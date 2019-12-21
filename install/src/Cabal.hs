module Cabal where

import           Development.Shake
import           Development.Shake.Command
import           Development.Shake.FilePath
import           Control.Monad
import           Data.Maybe                               ( isNothing
                                                          , isJust
                                                          )
import           Control.Monad.Extra                      ( whenMaybe )
import           System.Directory                         ( findExecutable
                                                          , copyFile
                                                          )

import           Version
import           Print
import           Env
import           Stack

execCabal :: CmdResult r => [String] -> Action r
execCabal = execCabalWithOriginalPath

execCabal_ :: [String] -> Action ()
execCabal_ = execCabalWithOriginalPath

execCabalWithOriginalPath :: CmdResult r => [String] -> Action r
execCabalWithOriginalPath = withoutStackCachedBinaries . (command [] "cabal")

cabalBuildData :: Action ()
cabalBuildData = do
  execCabal_ ["v2-build", "hoogle"]
  execCabal_ ["v2-exec", "hoogle", "generate"]

getGhcPathOfOrThrowError :: VersionNumber -> Action GhcPath
getGhcPathOfOrThrowError versionNumber = 
  getGhcPathOf versionNumber >>= \case
    Nothing -> do
      printInStars $ ghcVersionNotFoundFailMsg versionNumber
      error (ghcVersionNotFoundFailMsg versionNumber)
    Just p -> return p

cabalBuildHie :: VersionNumber -> Action ()
cabalBuildHie versionNumber = do
  ghcPath <- getGhcPathOfOrThrowError versionNumber
  execCabal_
    [ "v2-build"
    , "-w", ghcPath
    , "--write-ghc-environment-files=never"
    , "--max-backjumps=5000"
    , "--disable-tests"]

cabalInstallHie :: VersionNumber -> Action ()
cabalInstallHie versionNumber = do
  localBin <- getLocalBin
  cabalVersion <- getCabalVersion
  ghcPath <- getGhcPathOfOrThrowError versionNumber

  let isCabal3 = checkVersion [3,0,0,0] cabalVersion
      installDirOpt | isCabal3 = "--installdir"
                    | otherwise = "--symlink-bindir"
      installMethod | isWindowsSystem && isCabal3 = ["--install-method=copy"]
                    | otherwise = []
  execCabal_ $
    [ "v2-install"
    , "-w", ghcPath
    , "--write-ghc-environment-files=never"
    , installDirOpt, localBin
    , "exe:hie"
    , "--overwrite-policy=always"
    ]
    ++ installMethod

  let minorVerExe = "hie-" ++ versionNumber <.> exe
      majorVerExe = "hie-" ++ dropExtension versionNumber <.> exe  

  liftIO $ do
    copyFile (localBin </> "hie" <.> exe) (localBin </> minorVerExe)
    copyFile (localBin </> "hie" <.> exe) (localBin </> majorVerExe)

  printLine $   "Copied executables "
             ++ ("hie-wrapper" <.> exe) ++ ", "
             ++ ("hie" <.> exe) ++ ", "
             ++ majorVerExe ++ " and "
             ++ minorVerExe
             ++ " to " ++ localBin

installCabalWithStack :: Action ()
installCabalWithStack = do
  -- try to find existing `cabal` executable with appropriate version
  mbc <- withoutStackCachedBinaries (liftIO (findExecutable "cabal"))

  case mbc of
    Just c  -> do
      cabalVersion <- checkCabal
      printLine $ "There is already a cabal executable in $PATH with the required minimum version: " ++ cabalVersion
     -- install `cabal-install` if not already installed
    Nothing ->  execStackShake_ ["install", "cabal-install"]

checkCabal_ :: Action ()
checkCabal_ = checkCabal >> return ()

-- | check `cabal` has the required version
checkCabal :: Action String
checkCabal = do
  cabalVersion <- getCabalVersion
  unless (checkVersion requiredCabalVersion cabalVersion) $ do
    printInStars $ cabalInstallIsOldFailMsg cabalVersion
    error $ cabalInstallIsOldFailMsg cabalVersion
  return cabalVersion

getCabalVersion :: Action String
getCabalVersion = trimmedStdout <$> execCabal ["--numeric-version"]

-- | Error message when the `cabal` binary is an older version
cabalInstallIsOldFailMsg :: String -> String
cabalInstallIsOldFailMsg cabalVersion =
  "The `cabal` executable found in $PATH is outdated.\n"
    ++ "found version is `"
    ++ cabalVersion
    ++ "`.\n"
    ++ "required version is `"
    ++ versionToString requiredCabalVersion
    ++ "`."


requiredCabalVersion :: RequiredVersion
requiredCabalVersion | isWindowsSystem = requiredCabalVersionForWindows
                     | otherwise = [2, 4, 1, 0]

requiredCabalVersionForWindows :: RequiredVersion
requiredCabalVersionForWindows = [3, 0, 0, 0]

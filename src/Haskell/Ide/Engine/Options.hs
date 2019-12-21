{-# LANGUAGE CPP #-}
module Haskell.Ide.Engine.Options where

import           Options.Applicative.Simple

data GlobalOpts = GlobalOpts
  { optDebugOn       :: Bool
  , optLogFile       :: Maybe String
  , optLsp           :: Bool
  , optJson          :: Bool
  , projectRoot      :: Maybe String
  , optBiosVerbose   :: Bool
  , optCaptureFile   :: Maybe FilePath
  , optExamplePlugin :: Bool
  } deriving (Show)

globalOptsParser :: Parser GlobalOpts
globalOptsParser = GlobalOpts
  <$> switch
       ( long "debug"
      <> short 'd'
      <> help "Generate debug output"
       )
  <*> optional (strOption
       ( long "logfile"
      <> short 'l'
      <> metavar "LOGFILE"
      <> help "File to log to, defaults to stdout"
       ))
  <*> flag True True
       ( long "lsp"
       <> help "Enable the Language Server Protocol transport on STDIO (default)")
  <*> switch
       ( long "json"
       <> help "Enable JSON transport on STDIO")
  <*> optional (strOption
       ( long "project-root"
      <> short 'r'
      <> metavar "PROJECTROOT"
      <> help "Root directory of project, defaults to cwd"))
  <*> (switch
          ( long "bios-verbose"
          <> help "enable verbose logging for hie-bios"
          )
       <|>
       switch
          ( long "vomit"
          <> help "(deprecated) enable verbose logging for hie-bios"
          )
      )
  <*> optional (strOption
       ( long "capture"
      <> short 'c'
      <> metavar "CAPTUREFILE"
      <> help "File to capture the session to"
       ))
  <*> switch
       ( long "example"
       <> help "Enable Example2 plugin. Useful for developers only")

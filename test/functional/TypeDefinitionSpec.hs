module TypeDefinitionSpec where

import           Control.Monad.IO.Class
import           Language.Haskell.LSP.Test
import           Language.Haskell.LSP.Types
import           Haskell.Ide.Engine.PluginUtils
import           System.Directory
import           Test.Hspec
import           TestUtils

spec :: Spec
spec = describe "type definitions" $ do
  it "finds local definition of record variable"
    $ runSession hieCommand fullCaps "test/testdata/gototest"
    $ do
        doc  <- openDoc "src/Lib.hs" "haskell"
        defs <- getTypeDefinitions doc (toPos (11, 23))
        liftIO $ do
          fp <- canonicalizePath "test/testdata/gototest/src/Lib.hs"
          defs
            `shouldBe` [ Location (filePathToUri fp)
                                  (Range (toPos (8, 1)) (toPos (8, 29)))
                       ]
  it "finds local definition of newtype variable"
    $ runSession hieCommand fullCaps "test/testdata/gototest"
    $ do
        doc  <- openDoc "src/Lib.hs" "haskell"
        defs <- getTypeDefinitions doc (toPos (16, 21))
        liftIO $ do
          fp <- canonicalizePath "test/testdata/gototest/src/Lib.hs"
          defs
            `shouldBe` [ Location (filePathToUri fp)
                                  (Range (toPos (13, 1)) (toPos (13, 30)))
                       ]
  it "finds local definition of sum type variable"
    $ runSession hieCommand fullCaps "test/testdata/gototest"
    $ do
        doc  <- openDoc "src/Lib.hs" "haskell"
        defs <- getTypeDefinitions doc (toPos (21, 13))
        liftIO $ do
          fp <- canonicalizePath "test/testdata/gototest/src/Lib.hs"
          defs
            `shouldBe` [ Location (filePathToUri fp)
                                  (Range (toPos (18, 1)) (toPos (18, 26)))
                       ]
  it "finds local definition of sum type contructor"
    $ runSession hieCommand fullCaps "test/testdata/gototest"
    $ do
        doc  <- openDoc "src/Lib.hs" "haskell"
        defs <- getTypeDefinitions doc (toPos (24, 7))
        liftIO $ do
          fp <- canonicalizePath "test/testdata/gototest/src/Lib.hs"
          defs
            `shouldBe` [ Location (filePathToUri fp)
                                  (Range (toPos (18, 1)) (toPos (18, 26)))
                       ]
  it "can not find non-local definition of type def"
    $ runSession hieCommand fullCaps "test/testdata/gototest"
    $ do
        doc  <- openDoc "src/Lib.hs" "haskell"
        defs <- getTypeDefinitions doc (toPos (30, 17))
        liftIO $ defs `shouldBe` []

  it "find local definition of type def"
    $ runSession hieCommand fullCaps "test/testdata/gototest"
    $ do
        doc      <- openDoc "src/Lib.hs" "haskell"
        defs <- getTypeDefinitions doc (toPos (35, 16))
        liftIO $ do
          fp <- canonicalizePath "test/testdata/gototest/src/Lib.hs"
          defs
            `shouldBe` [ Location (filePathToUri fp)
                                  (Range (toPos (18, 1)) (toPos (18, 26)))
                       ]

  it "find type-definition of type def in component"
    $ pendingWith "Finding symbols cross module is currently not supported"
    -- $ runSession hieCommand fullCaps "test/testdata/gototest"
    -- $ do
    --     doc      <- openDoc "src/Lib2.hs" "haskell"
    --     otherDoc <- openDoc "src/Lib.hs" "haskell"
    --     closeDoc otherDoc
    --     defs <- getTypeDefinitions doc (toPos (13, 20))
    --     liftIO $ do
    --       fp <- canonicalizePath "test/testdata/gototest/src/Lib.hs"
    --       defs
    --         `shouldBe` [ Location (filePathToUri fp)
    --                               (Range (toPos (8, 1)) (toPos (8, 29)))
    --                    ]
  it "find definition of parameterized data type"
    $ runSession hieCommand fullCaps "test/testdata/gototest"
    $ do
        doc  <- openDoc "src/Lib.hs" "haskell"
        defs <- getTypeDefinitions doc (toPos (40, 19))
        liftIO $ do
          fp <- canonicalizePath "test/testdata/gototest/src/Lib.hs"
          defs
            `shouldBe` [ Location (filePathToUri fp)
                                  (Range (toPos (37, 1)) (toPos (37, 31)))
                       ]

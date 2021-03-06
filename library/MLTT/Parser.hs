module MLTT.Parser where

import           Control.Monad.Catch
import           Control.Monad.IO.Class

import qualified Data.HashSet                as HS

import           Text.Parser.Char
import           Text.Parser.Combinators
import           Text.Parser.Expression
import           Text.Parser.LookAhead
import           Text.Parser.Token
import           Text.Parser.Token.Highlight

import qualified Text.Trifecta.Delta         as Trifecta
import qualified Text.Trifecta.Parser        as Trifecta
import qualified Text.Trifecta.Result        as Trifecta

import           MLTT.Types

type Parser = Trifecta.Parser

piSym, lambdaSym :: String
-- piSym     = "Π"
-- lambdaSym = "λ"
piSym     = "pi"
lambdaSym = "lambda"

variableStyle :: IdentifierStyle Parser
variableStyle = IdentifierStyle
                { _styleName              = "variable"
                , _styleStart             = letter
                , _styleLetter            = alphaNum
                , _styleReserved          = HS.fromList [piSym, lambdaSym]
                , _styleHighlight         = Identifier
                , _styleReservedHighlight = ReservedIdentifier }

variableP :: Parser Variable
variableP = NamedVar <$> ident variableStyle

referenceP :: Parser Expr
referenceP = Var <$> variableP

universeP :: Parser Expr
universeP = Universe . fromInteger <$> (text "Set" >> natural)

abstractionP :: String -> Parser Abstraction
abstractionP binder = do symbol binder
                         v <- variableP
                         colon
                         t <- exprP
                         dot
                         e <- exprP
                         return $ Abs v t e

piP :: Parser Expr
piP = Pi <$> abstractionP piSym

lambdaP :: Parser Expr
lambdaP = Lambda <$> abstractionP lambdaSym

appP :: Parser Expr
appP = exprP >> someSpace >> exprP

exprP :: Parser Expr
exprP = choice [ universeP
               , piP
               , lambdaP
               , parens exprP
               , referenceP
               , appP ]

testParseExpr :: (MonadIO m) => String -> m ()
testParseExpr = Trifecta.parseTest exprP

parseExpr' :: (MonadThrow m) => Trifecta.Delta -> String -> m Expr
parseExpr' delta str = case Trifecta.parseString exprP delta str
                       of Trifecta.Success s -> return s
                          Trifecta.Failure d -> throwParseException d

parseExpr :: (MonadThrow m) => String -> m Expr
parseExpr = parseExpr' mempty

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct MatrixTypeMacro: MemberMacro {
    /// Creates a type like `(Double, Double, Double, ...)` with `count` repetitions.
    private static func makeElementType(count: Int) -> TypeSyntax {
        TypeSyntax(
            TupleTypeSyntax(
                elements: TupleTypeElementListSyntax {
                    for _ in 0 ..< count {
                        TupleTypeElementSyntax(type: TypeSyntax("Double"))
                    }
                }
            )
        )
    }

    /// Creates an initializer signature and implementation taking `count` parameters,
    /// and assigning to the local storage the tuple formed by those parameter values
    private static func makeInitializer(count: Int) -> DeclSyntax {
        let signature = FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax {
                for i in 0..<count {
                    "_ x\(raw: i): Double"
                }
            }
        )

        return DeclSyntax(
            InitializerDeclSyntax(signature: signature) {
                let leftOperand = ExprSyntax("self.data")
                let assignmentExpr = AssignmentExprSyntax()
                let rightOperand = TupleExprSyntax {
                    for i in 0..<count {
                        LabeledExprSyntax(expression: ExprSyntax("x\(raw: i)"))
                    }
                }
                InfixOperatorExprSyntax(
                    leftOperand: leftOperand,
                    operator: assignmentExpr,
                    rightOperand: rightOperand)
            }
        )
    }

    /// Creates a subscript function, for both `set`ting and `get`ting values,
    /// taking into account the `order` of the correspondent matrix
    private static func makeSubscriptFunction(order: Int) -> DeclSyntax {
        let parameterClause = FunctionParameterClauseSyntax {
            "row: Int"
            "column: Int"
        }

        let returnClause = ReturnClauseSyntax(type: IdentifierTypeSyntax(name: "Double"))

        let getAccessorDecl = AccessorDeclSyntax(accessorSpecifier: .keyword(.get)) {
            CodeBlockItemSyntax(item: .decl(DeclSyntax(
                VariableDeclSyntax(
                    .let,
                    name: PatternSyntax("index"),
                    initializer: InitializerClauseSyntax(
                        value: ExprSyntax("column + row * \(raw: order)")
                    ))))
            )
            CodeBlockItemSyntax(item: .expr(ExprSyntax(
                SwitchExprSyntax(subject: ExprSyntax("index")) {
                    for i in 0..<order*order {
                        SwitchCaseSyntax("case \(raw: i): return self.data.\(raw: i)")
                    }
                    SwitchCaseSyntax("default: fatalError()")
                }
            )))
        }

        let setAccessorDecl =  AccessorDeclSyntax(
            accessorSpecifier: .keyword(.set),
            parameters: AccessorParametersSyntax(name: "newValue")) {
            CodeBlockItemSyntax(item: .decl(DeclSyntax(
                VariableDeclSyntax(
                    .let,
                    name: PatternSyntax("index"),
                    initializer: InitializerClauseSyntax(
                        value: ExprSyntax("column + row * \(raw: order)")
                    ))))
            )
            CodeBlockItemSyntax(item: .expr(ExprSyntax(
                SwitchExprSyntax(subject: ExprSyntax("index")) {
                    for i in 0..<order*order {
                        SwitchCaseSyntax("case \(raw: i): self.data.\(raw: i) = newValue")
                    }
                    SwitchCaseSyntax("default: fatalError()")
                }
            )))
        }


        let accessorBlock = AccessorBlockSyntax(
            accessors: .accessors(
                AccessorDeclListSyntax {
                    getAccessorDecl
                    setAccessorDecl
                }))

        return DeclSyntax(
            SubscriptDeclSyntax(
                parameterClause: parameterClause,
                returnClause: returnClause,
                accessorBlock: accessorBlock))
    }

    /// Creates a function that computes the submatrix correspondent with the
    /// `row` and `column` value passed in
    private static func makeSubmatrixFunction(order: Int) -> DeclSyntax {
        let submatrixOrder = order-1

        let signature = FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax {
                "row: Int"
                "column: Int"
            },
            returnClause: ReturnClauseSyntax(type: IdentifierTypeSyntax(name: "Matrix\(raw: submatrixOrder)"))
        )

        let zeroes = [String](repeating: "0", count: submatrixOrder*submatrixOrder).joined(separator: ",")

        return DeclSyntax(
            FunctionDeclSyntax(
                name: "submatrix",
                signature: signature) {
                    CodeBlockItemSyntax(item: .decl(DeclSyntax(
                        VariableDeclSyntax(
                            .var,
                            name: PatternSyntax("sm"),
                            initializer: InitializerClauseSyntax(
                                value: ExprSyntax("Matrix\(raw: submatrixOrder)(\(raw: zeroes))")
                            ))))
                    )
                    CodeBlockItemSyntax(item: .decl(DeclSyntax(
                        VariableDeclSyntax(
                            .var,
                            name: PatternSyntax("targetRow"),
                            initializer: InitializerClauseSyntax(
                                value: ExprSyntax("0")
                            ))))
                    )
                    // Outer for-loop
                    CodeBlockItemSyntax(
                        item: .stmt(
                            StmtSyntax(
                                ForStmtSyntax(
                                    pattern: PatternSyntax("sourceRow"),
                                    sequence: ExprSyntax("0...\(raw: order-1)")) {
                                        CodeBlockItemSyntax(item: .expr(
                                            ExprSyntax(
                                                IfExprSyntax(
                                                    conditions: ConditionElementListSyntax {
                                                        ExprSyntax("sourceRow == row")
                                                    },
                                                    body: CodeBlockSyntax {
                                                        StmtSyntax("continue")
                                                    })
                                            ))
                                        )
                                        CodeBlockItemSyntax(item: .decl(DeclSyntax(
                                            VariableDeclSyntax(
                                                .var,
                                                name: PatternSyntax("targetColumn"),
                                                initializer: InitializerClauseSyntax(
                                                    value: ExprSyntax("0")
                                                ))))
                                        )

                                        // Inner for-loop
                                        CodeBlockItemSyntax(
                                            item: .stmt(
                                                StmtSyntax(
                                                    ForStmtSyntax(
                                                        pattern: PatternSyntax("sourceColumn"),
                                                        sequence: ExprSyntax("0...\(raw: order-1)")) {
                                                            CodeBlockItemSyntax(item: .expr(
                                                                ExprSyntax(
                                                                    IfExprSyntax(
                                                                        conditions: ConditionElementListSyntax {
                                                                            ExprSyntax("sourceColumn == column")
                                                                        },
                                                                        body: CodeBlockSyntax {
                                                                            StmtSyntax("continue")
                                                                        })
                                                                ))
                                                            )
                                                            CodeBlockItemSyntax(
                                                                item: .expr(
                                                                    ExprSyntax(
                                                                        InfixOperatorExprSyntax(
                                                                            leftOperand: ExprSyntax("sm[targetRow, targetColumn]"),
                                                                            operator: BinaryOperatorExprSyntax(operator: "="),
                                                                            rightOperand: ExprSyntax("self[sourceRow, sourceColumn]")
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                            CodeBlockItemSyntax(
                                                                item: .expr(
                                                                    ExprSyntax(
                                                                        InfixOperatorExprSyntax(
                                                                            leftOperand: ExprSyntax("targetColumn"),
                                                                            operator: BinaryOperatorExprSyntax(operator: "+="),
                                                                            rightOperand: ExprSyntax("1")
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        }
                                                    )
                                                )
                                        )

                                        CodeBlockItemSyntax(
                                            item: .expr(
                                                ExprSyntax(
                                                    InfixOperatorExprSyntax(
                                                        leftOperand: ExprSyntax("targetRow"),
                                                        operator: BinaryOperatorExprSyntax(operator: "+="),
                                                        rightOperand: ExprSyntax("1")
                                                    )
                                                )
                                            )
                                        )
                                    }
                            )
                        )
                    )
                    CodeBlockItemSyntax(
                        item: .stmt(
                            StmtSyntax(
                                ReturnStmtSyntax(
                                    returnKeyword: .keyword(.return),
                                    expression: ExprSyntax("sm")
                                )
                            )
                        )
                    )
                }
            )
    }

    /// Creates a function that computes a minor of the matrix of order `order`
    private static func makeMinorFunction(order: Int) -> DeclSyntax {
        let signature = FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax {
                "row: Int"
                "column: Int"
            },
            returnClause: ReturnClauseSyntax(type: IdentifierTypeSyntax(name: "Double"))
        )

        return DeclSyntax(
            FunctionDeclSyntax(
                name: "minor",
                signature: signature) {
                    CodeBlockItemSyntax(item: .expr(
                        ExprSyntax("self.submatrix(row: row, column: column).determinant()")
                    ))
                }
            )
    }

    /// Creates a function that computes the cofactor of the matrix for a given row and column
    /// Note that the implementation of this function is not dependent on the order of the matrix
    private static func makeCofactorFunction() -> DeclSyntax {
        let signature = FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax {
                "row: Int"
                "column: Int"
            },
            returnClause: ReturnClauseSyntax(type: IdentifierTypeSyntax(name: "Double"))
        )

        return DeclSyntax(
            FunctionDeclSyntax(
                name: "cofactor",
                signature: signature) {
                    CodeBlockItemSyntax(item: .decl(DeclSyntax(
                        VariableDeclSyntax(
                            .let,
                            name: PatternSyntax("coefficient"),
                            initializer: InitializerClauseSyntax(
                                value: ExprSyntax("(row + column)%2 == 0 ? 1.0 : -1.0")
                            ))))
                    )
                    CodeBlockItemSyntax(item: .decl(DeclSyntax(
                        VariableDeclSyntax(
                            .let,
                            name: PatternSyntax("minor"),
                            initializer: InitializerClauseSyntax(
                                value: ExprSyntax("self.minor(row: row, column: column)")
                            ))))
                    )
                    CodeBlockItemSyntax(
                        item: .stmt(
                            StmtSyntax(
                                ReturnStmtSyntax(
                                    returnKeyword: .keyword(.return),
                                    expression: ExprSyntax("coefficient*minor")
                                )
                            )
                        )
                    )
                }
        )
    }

    /// Creates a function that computes the determinant for matrices of order 2 only
    private static func makeDeterminantBaseFunction() -> DeclSyntax {
        let signature = FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax {},
            returnClause: ReturnClauseSyntax(type: IdentifierTypeSyntax(name: "Double"))
        )

        return DeclSyntax(
            FunctionDeclSyntax(
                name: "determinant",
                signature: signature) {
                    CodeBlockItemSyntax(
                        item: .stmt(
                            StmtSyntax(
                                ReturnStmtSyntax(
                                    returnKeyword: .keyword(.return),
                                    expression: ExprSyntax("self[0, 0]*self[1, 1] - self[0, 1]*self[1, 0]")
                                )
                            )
                        )
                    )
                }
        )
    }

    /// Creates a function that computes the determinant for matrices of order 3 and above
    private static func makeDeterminantRecursiveFunction(order: Int) -> DeclSyntax {
        let signature = FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax {},
            returnClause: ReturnClauseSyntax(type: IdentifierTypeSyntax(name: "Double"))
        )

        return DeclSyntax(
            FunctionDeclSyntax(
                name: "determinant",
                signature: signature) {
                    CodeBlockItemSyntax(item: .decl(DeclSyntax(
                        VariableDeclSyntax(
                            .var,
                            name: PatternSyntax("value"),
                            initializer: InitializerClauseSyntax(
                                value: ExprSyntax("0.0")
                            ))))
                    )
                    CodeBlockItemSyntax(
                        item: .stmt(
                            StmtSyntax(
                                ForStmtSyntax(
                                    pattern: PatternSyntax("i"),
                                    sequence: ExprSyntax("0...\(raw: order-1)")) {
                                        CodeBlockItemSyntax(
                                            item: .expr(
                                                ExprSyntax(
                                                    InfixOperatorExprSyntax(
                                                        leftOperand: ExprSyntax("value"),
                                                        operator: BinaryOperatorExprSyntax(operator: "+="),
                                                        rightOperand: ExprSyntax("self.cofactor(row: 0, column: i)*self[0, i]")
                                                    )
                                                )
                                            )
                                        )
                                    }
                            )
                        )
                    )
                    CodeBlockItemSyntax(
                        item: .stmt(
                            StmtSyntax(
                                ReturnStmtSyntax(
                                    returnKeyword: .keyword(.return),
                                    expression: ExprSyntax("value")
                                )
                            )
                        )
                    )
                }
        )
    }

    public static func expansion<D: DeclGroupSyntax, C: MacroExpansionContext> (
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: D,
        in context: C
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let _ = declaration.as(StructDeclSyntax.self) else {
            fatalError("This macro only applies to structs!!!")
        }

        guard case let .argumentList(argList) = node.arguments,
              let arg = argList.first else {
            fatalError("Need to supply order as only argument!!!")
        }
        guard case let .integerLiteral(rawOrder) = arg.expression.as(IntegerLiteralExprSyntax.self)?.literal.tokenKind,
              let order = Int(rawOrder) else {
            fatalError("Rank needs to be an integer!!!")
        }
        let elementCount = order*order

        let localStorageDecl: DeclSyntax = """
            var data: \(makeElementType(count: elementCount))
        """

        let initializerDecl = makeInitializer(count: elementCount)

        let subscriptDecl = makeSubscriptFunction(order: order)

        if order == 2 {
            let determinantDecl = makeDeterminantBaseFunction()

            return [
                localStorageDecl,
                initializerDecl,
                subscriptDecl,
                determinantDecl,
            ]
        } else {
            let submatrixDecl = makeSubmatrixFunction(order: order)
            let minorDecl = makeMinorFunction(order: order)
            let cofactorDecl = makeCofactorFunction()
            let determinantDecl = makeDeterminantRecursiveFunction(order: order)

            return [
                localStorageDecl,
                initializerDecl,
                subscriptDecl,
                submatrixDecl,
                minorDecl,
                cofactorDecl,
                determinantDecl,
            ]
        }
    }
    
}

@main
struct MatrixTypesPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MatrixTypeMacro.self,
    ]
}

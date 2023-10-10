// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: arbitrary)
public macro expandMatrixType(order: Int) = #externalMacro(module: "MatrixTypesMacros", type: "MatrixTypeMacro")


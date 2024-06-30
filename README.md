MatrixMaster.sol library helps matrix operations in Solidity. It uses ABDKMathQuad library to support floating-point math operations and MM_MatrixHelper.sol for helper functions like string to quad conversion etc. Library supports the functions below:

**Basic Operations**
1. createMatrix
Matrix creation (empty or with values) in string format: [(v1,v2, ...),(v3, v4, ...)]. On this input, each round bracket defines a row and v1, v2, v3, v4, etc. are values.

2. createVector
Vector creation in string format: [v1, v2, v2, ...]. Library treats and creates the vector as matrix.

3. clearMatrix
Clears the matrix values

4. getMatrix
Shows matrix values

5. updateMatrixValue
Updates matrix value by row and column number

6. readMatrixValue
Shows a value for row and column

**Math Operations**
1. addMatrices
Adds two matrices

2. subtractMatrices
Subtracts two matrices
   
3. multiplyMatrices
Multiplies two matrices

4. transposeMatrix
Transposes a given matrix

5. invertMatrix
Inverts an NxN matrix

6. performGaussianElimination
Performs Gaussian Elimination on the given augmented matrix

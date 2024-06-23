// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ABDKMathQuad.sol";
import "./MM_MatrixHelper.sol";
import "./MM_MatrixAdvance.sol";

// The MatrixMaster library uses ABDKMathQuad for high-precision matrix operations,
// allowing creation and manipulation of matrices. Users can define matrices
// by dimensions or values, perform updates, and multiply matrices with precise 128-bit
// floating-point arithmetic, making it ideal for complex computations on the Ethereum blockchain.
library MatrixMaster {
    using ABDKMathQuad for bytes16;
    using MM_MatrixHelper for string;
    using MM_MatrixHelper for bytes16;
    using MM_MatrixHelper for bytes;
    using MM_MatrixHelper for uint256;

    uint256 private constant PRECISION = 10; // precision can be defined

    struct Matrix {
        bytes16[][] data;
        uint256 rows;
        uint256 cols;
    }

    /**
     * @notice Creates an empty matrix
     * @param rows The number of rows for the matrix
     * @param cols The number of columns for the matrix
     * @return The newly created empty matrix
     */
    function createEmptyMatrix(uint256 rows, uint256 cols) public pure returns (Matrix memory) {
        require(rows > 0 && cols > 0, "Row/Column count cannot be zero.");

        Matrix memory matrix;
        matrix.rows = rows;
        matrix.cols = cols;
        matrix.data = new bytes16[][](rows);

        for (uint256 i = 0; i < rows; i++) {
            matrix.data[i] = new bytes16[](cols);
        }

        return matrix;
    }

    /**
     * @notice Creates a matrix with input values
     * @param matrixValues Input format is "[(v1,v2,...),(v3,v4,...),...]" as a string
     *                     where each round bracket defines a row and v1, v2, v3, v4, etc. are values
     *                     example: "[(-3.1,-3.2,3.1),(2.1,2.1,2.1)]"
     * @return The newly created matrix
     * @dev Throws if the input format is invalid
     */
    function createMatrix(string memory matrixValues) public pure returns (Matrix memory) {
        bytes memory inputBytes = bytes(matrixValues);

        require(inputBytes[0] == "[" && inputBytes[inputBytes.length - 1] == "]", "Invalid input format");

        inputBytes = inputBytes.slice(1, inputBytes.length - 2); // Remove the outer brackets from the input

        string[] memory rows = string(inputBytes).split("),("); // Split the input into rows using "),(" as the delimiter

        uint256 numRows = rows.length;
        uint256 numCols = rows[0].split(",").length; // Split the first row to determine the number of columns

        Matrix memory matrix = createEmptyMatrix(numRows, numCols);

        for (uint256 i = 0; i < numRows; i++) {
            string[] memory cols = rows[i].split(",");
            require(cols.length == numCols, "Inconsistent number of columns in row");
            for (uint256 j = 0; j < numCols; j++) {
                bytes16 value = cols[j].stringToQuad();
                matrix.data[i][j] = value;
            }
        }

        return matrix;
    }

    /**
     * @notice Creates a vector from a single array input
     * @param vectorValues Input format is "[v1,v2,v3,...]" as a string
     *                     where v1, v2, v3, etc. are values
     *                     example: "[1.0,2.0,3.0]"
     * @return The newly created matrix representing the vector
     * @dev Throws if the input format is invalid
     */
    function createVector(string memory vectorValues) public pure returns (Matrix memory) {
        bytes memory inputBytes = bytes(vectorValues);

        require(inputBytes[0] == "[" && inputBytes[inputBytes.length - 1] == "]", "Invalid input format");

        inputBytes = inputBytes.slice(1, inputBytes.length - 2); // Remove the outer brackets from the input

        string[] memory values = string(inputBytes).split(","); // Split the input into values using "," as the delimiter

        string memory matrixValues = "[";
        for (uint256 i = 0; i < values.length; i++) {
            matrixValues = string(abi.encodePacked(matrixValues, "(", values[i], ")"));
            if (i < values.length - 1) {
                matrixValues = string(abi.encodePacked(matrixValues, ","));
            }
        }
        matrixValues = string(abi.encodePacked(matrixValues, "]"));

        return createMatrix(matrixValues);
    }

    /**
     * @notice Clears a matrix's data
     * @param matrix The matrix to be cleared
     */
    function clearMatrix(Matrix storage matrix) public {
        delete matrix.data;
        matrix.rows = 0;
        matrix.cols = 0;
    }

    /**
     * @notice Returns the matrix as a string
     * @param matrix The matrix to be shown
     * @return Matrix in format of "[(v1,v2,...),(v3,v4,...),...]" as a string
     *         where each round bracket defines a row and v1, v2, v3, v4, etc. are values
     *         example: "[(-3.1,-3.2,3.1),(2.1,2.1,2.1)]"
     */
    function getMatrix(Matrix memory matrix) public pure returns (string memory) {
        string memory result = "[";
        for (uint256 i = 0; i < matrix.rows; i++) {
            result = string(abi.encodePacked(result, "("));
            for (uint256 j = 0; j < matrix.cols; j++) {
                result = string(abi.encodePacked(result, matrix.data[i][j].quadToString()));
                if (j < matrix.cols - 1) {
                    result = string(abi.encodePacked(result, ","));
                }
            }
            result = string(abi.encodePacked(result, ")"));
            if (i < matrix.rows - 1) {
                result = string(abi.encodePacked(result, ","));
            }
        }
        result = string(abi.encodePacked(result, "]"));
        return result;
    }

    /**
     * @notice Updates a specific element of a matrix
     * @param matrix The matrix to be updated
     * @param row Row number of the element to be updated (0-based index)
     * @param col Column number of the element to be updated (0-based index)
     * @param newValue New value of the element, in 128-bit quadruple precision floating-point format (bytes16)
     */
    function updateMatrixValue(Matrix storage matrix, uint256 row, uint256 col, bytes16 newValue) public {
        setValue(matrix, row, col, newValue);
    }

    /**
     * @notice Internal function to set an element's value of a matrix
     * @param matrix The matrix to be updated (passed by storage reference)
     * @param row Row number of the element to be set (0-based index)
     * @param col Column number of the element to be set (0-based index)
     * @param value Value of the element to be set, in 128-bit quadruple precision floating-point format (bytes16)
     * @dev Throws if the specified row or column is out of bounds
     */
    function setValue(Matrix storage matrix, uint256 row, uint256 col, bytes16 value) internal {
        require(row < matrix.rows && col < matrix.cols, "Index out of bounds");
        matrix.data[row][col] = value;
    }

    /**
     * @notice Returns a specific element of a matrix as a string
     * @param matrix The matrix
     * @param row Row number of the element to be read (0-based index)
     * @param col Column number of the element to be read (0-based index)
     * @return The value of the specified element as a string
     * @dev Throws if the specified row or column is out of bounds
     */
    function readMatrixValue(Matrix memory matrix, uint256 row, uint256 col) public pure returns (string memory) {
        return getValue(matrix, row, col).quadToString();
    }

    /**
     * @notice Internal function to return a specific element of a matrix
     * @param matrix The matrix
     * @param row Row number of the element to be read (0-based index)
     * @param col Column number of the element to be read (0-based index)
     * @return The value of the specified element as a bytes16 (128-bit quadruple precision floating-point number)
     * @dev Throws if the specified row or column is out of bounds
     */
    function getValue(Matrix memory matrix, uint256 row, uint256 col) internal pure returns (bytes16) {
        require(row < matrix.rows && col < matrix.cols, "Index out of bounds");
        return matrix.data[row][col];
    }


    // Matrix Calculations ---------------------------------------------------------------------------------------

    /**
     * @notice Adds two matrices and returns the result in a new matrix
     * @param matrix1 The first matrix to be added
     * @param matrix2 The second matrix to be added
     * @return A new matrix representing the result of the matrix addition
     * @dev Throws if the dimensions of the matrices do not match
     */
    function addMatrices(Matrix memory matrix1, Matrix memory matrix2) public pure returns (Matrix memory) {
        require(matrix1.rows == matrix2.rows && matrix1.cols == matrix2.cols, "Matrix dimensions must match");

        Matrix memory resultMatrix = createEmptyMatrix(matrix1.rows, matrix1.cols);

        for (uint256 i = 0; i < matrix1.rows; i++) {
            for (uint256 j = 0; j < matrix1.cols; j++) {
                resultMatrix.data[i][j] = matrix1.data[i][j].add(matrix2.data[i][j]);
            }
        }
        return resultMatrix;
    }

    /**
     * @notice Subtracts the second matrix from the first matrix and returns the result in a new matrix
     * @param matrix1 The first matrix (minuend)
     * @param matrix2 The second matrix (subtrahend)
     * @return A new matrix representing the result of the matrix subtraction
     * @dev Throws if the dimensions of the matrices do not match
     */
    function subtractMatrices(Matrix memory matrix1, Matrix memory matrix2) public pure returns (Matrix memory) {
        require(matrix1.rows == matrix2.rows && matrix1.cols == matrix2.cols, "Matrix dimensions must match");

        Matrix memory resultMatrix = createEmptyMatrix(matrix1.rows, matrix1.cols);

        for (uint256 i = 0; i < matrix1.rows; i++) {
            for (uint256 j = 0; j < matrix1.cols; j++) {
                resultMatrix.data[i][j] = matrix1.data[i][j].sub(matrix2.data[i][j]);
            }
        }
        return resultMatrix;
    }

    /**
     * @notice Multiplies two matrices and returns the result in a new matrix
     * @param matrix1 The first matrix to be multiplied
     * @param matrix2 The second matrix to be multiplied
     * @return A new matrix representing the result of the matrix multiplication
     * @dev Throws if the number of columns in the first matrix does not equal the number of rows in the second matrix
     */
    function multiplyMatrices(Matrix memory matrix1, Matrix memory matrix2) public pure returns (Matrix memory) {
        require(matrix1.cols == matrix2.rows, "Matrix multiplication not possible");

        Matrix memory resultMatrix = createEmptyMatrix(matrix1.rows, matrix2.cols);

        for (uint256 i = 0; i < matrix1.rows; i++) {
            for (uint256 j = 0; j < matrix2.cols; j++) {
                bytes16 sum = ABDKMathQuad.fromUInt(0);
                for (uint256 k = 0; k < matrix1.cols; k++) {
                    sum = sum.add(matrix1.data[i][k].mul(matrix2.data[k][j]));
                }
                resultMatrix.data[i][j] = sum;
            }
        }

        return resultMatrix;
    }

    /**
     * @notice Transposes a given matrix and returns the result in a new matrix
     * @param matrix Matrix to be transposed
     * @return A new matrix representing the transposed matrix
     */
    function transposeMatrix(Matrix memory matrix) public pure returns (Matrix memory) {
        Matrix memory transposedMatrix = createEmptyMatrix(matrix.cols, matrix.rows);

        for (uint256 i = 0; i < matrix.rows; i++) {
            for (uint256 j = 0; j < matrix.cols; j++) {
                transposedMatrix.data[j][i] = matrix.data[i][j];
            }
        }

        return transposedMatrix;
    }

    /**
     * @notice Inverts an NxN matrix
     * @param matrix The NxN matrix to be inverted
     * @return The inverted matrix
     * @dev Throws if the matrix is not square or if the matrix is singular (non-invertible)
     */
    function invertMatrix(Matrix memory matrix) public pure returns (Matrix memory) {
        require(matrix.rows == matrix.cols, "Matrix must be square");

        uint256 n = matrix.rows;
        Matrix memory augmented = createEmptyMatrix(n, 2 * n);

        // Initialize the augmented matrix [matrix | I]
        for (uint256 i = 0; i < n; i++) {
            for (uint256 j = 0; j < n; j++) {
                augmented.data[i][j] = matrix.data[i][j];
            }
            augmented.data[i][i + n] = ABDKMathQuad.fromUInt(1);
        }

        // Perform Gaussian elimination
        for (uint256 i = 0; i < n; i++) {
            // Find the pivot
            bytes16 pivot = augmented.data[i][i];
            require(pivot != ABDKMathQuad.fromUInt(0), "Matrix is singular and cannot be inverted");

            // Normalize the pivot row
            for (uint256 j = 0; j < 2 * n; j++) {
                augmented.data[i][j] = augmented.data[i][j].div(pivot);
            }

            // Eliminate the column
            for (uint256 k = 0; k < n; k++) {
                if (k != i) {
                    bytes16 factor = augmented.data[k][i];
                    for (uint256 j = 0; j < 2 * n; j++) {
                        augmented.data[k][j] = augmented.data[k][j].sub(factor.mul(augmented.data[i][j]));
                    }
                }
            }
        }

        // Extract the inverse matrix from the augmented matrix
        Matrix memory inverse = createEmptyMatrix(n, n);
        for (uint256 i = 0; i < n; i++) {
            for (uint256 j = 0; j < n; j++) {
                inverse.data[i][j] = augmented.data[i][j + n];
            }
        }
        return inverse;
    }

    function fromBytes16Array(bytes16[][] memory array, uint256 rows, uint256 cols) internal pure returns (Matrix memory) {
        return Matrix({data: array, rows: rows, cols: cols});
    }
    
    /**
     * @notice Calls internal gaussianElimination method to solve matrix
     * @param matrix The augmented matrix representing the system of equations [A|B]
     * @return string array with solutions
     */
    function performGaussianElimination(MatrixMaster.Matrix memory matrix) public pure returns (string[] memory) {
        bytes16[] memory solution5 = gaussianElimination(matrix);

        string[] memory readableSolution = new string[](solution5.length);
        for (uint i = 0; i < solution5.length; i++) {
            readableSolution[i] = MM_MatrixHelper.quadToString(solution5[i]);//ABDKMathQuad.toString(solution[i]);
        }

        return readableSolution;
    }

    /**
     * @notice Performs Gaussian Elimination on the given augmented matrix
     * @param matrix The augmented matrix representing the system of equations [A|B]
     * @return The solution vector in ABDK Quad number format
     * @dev Throws if the matrix is singular (non-solvable)
     */
    function gaussianElimination(MatrixMaster.Matrix memory matrix) internal pure returns (bytes16[] memory) {
        uint n = matrix.rows;
        bytes16[] memory x = new bytes16[](n);

        // Forward Elimination
        for (uint i = 0; i < n; i++) {
            require(matrix.data[i][i] != ABDKMathQuad.fromUInt(0), "Divide by zero detected!");

            for (uint j = i + 1; j < n; j++) {
                bytes16 ratio = ABDKMathQuad.div(matrix.data[j][i], matrix.data[i][i]);

                for (uint k = 0; k < matrix.cols; k++) {
                    matrix.data[j][k] = ABDKMathQuad.sub(matrix.data[j][k], ABDKMathQuad.mul(ratio, matrix.data[i][k]));
                }
            }
        }

        // Back Substitution
        x[n - 1] = ABDKMathQuad.div(matrix.data[n - 1][matrix.cols - 1], matrix.data[n - 1][n - 1]);

        for (int i = int(n) - 2; i >= 0; i--) {
            x[uint(i)] = matrix.data[uint(i)][matrix.cols - 1];

            for (uint j = uint(i) + 1; j < n; j++) {
                x[uint(i)] = ABDKMathQuad.sub(x[uint(i)], ABDKMathQuad.mul(matrix.data[uint(i)][j], x[j]));
            }

            x[uint(i)] = ABDKMathQuad.div(x[uint(i)], matrix.data[uint(i)][uint(i)]);
        }

        return x;
    }
}
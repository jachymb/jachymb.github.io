---
title: 'Emulating a quantum computer'
layout: post
date: 2024-03-18
tags: [quantum computation,python]
pin: true
math: true
lang: en
---

I programmed a simple quantum computer emulator as an [open source hobby Python project](https://github.com/jachymb/quantum-computer).
This isn't directly related the work I do for living, but I studied quantum computation at university
and always found this topic interesting.
I did my bachelor's thesis on quantum information theory,
which even resulted in a mathematical publication. \[1\]

Here, I wanted to explain in simple terms, how quantum computation can be emulated on a classical computer.

I don't go much into the _why_ here, mostly just explain the _how_. 
A basic understanding of the mathematical formalism of quantum theory is expected from the reader.

# Qubits
Qubit is the basic informational unit of quantum computation. 
Upon measurement, it's observed as a classical 0 or 1 bit.
But in its quantum state, it can be in any superposition of the two 
and it can also be entangled to other qubits. 
Entangled quantum systems act as one irreducible system in some way,
so since $n$ bits can represent $2^n$ different states and the entangles system
may be in a superposition of all of them, and the superposition coefficients are 
complex numbers, a system of $n$ qubits is described by $2^n$ complex-valued. 

Because of unitarity of quantum system evolution, this vector is normed.
This removes on degree of freedom (DoF). Furthermore, there is something called global phase shift invariance,
which in this sense means multiplying the vector by a scalar complex unit doesn't change anything essential.
This removes yet another DoF. Since a complex number as 2 DoF, the state has total $2\cdot2^n - 2$ DoF.
In particular, a 1-qubit system is topologically a 2-dimensional object, known as the [Bloch sphere](https://en.wikipedia.org/wiki/Bloch_sphere). 

We canonically represent the qubit corresponding to the bit 0 (false) as $\begin{pmatrix}0 \\ 1\end{pmatrix}$ and the bit 1 (true) as $\begin{pmatrix}1 \\ 0\end{pmatrix}$.
To represent a qubit array, we take the tensor product of all of those. 
For a classical bit array, this would be a vector with 0s everywhere except for a 1 at the position given by the binary number the bit array represents (counted from zero at the bottom.)
Implementationally, this is achieved easily in Python using `np.kron`.

# Quantum gates
The qubit number is always preserved. 
Any operation done on qubits is thus an operation $U: \mathbb{C}^{2^n} \to \mathbb{C}^{2^n}$.
However, this can't be arbitrary. The quantum theory further dictates, that it must be a linear unitary operation.
It can thus be represented by a matrix, where [unitarity](https://en.wikipedia.org/wiki/Unitary_matrix) is defined as $UU^{\dagger} = I$,
where the dagger symbol is the Hermitian adjoint.
This class of matrices has several interesting properties, but perhaps the most important is that it's easily invertible.
A quantum computation, can thus be always reversed. 

# Universal gates
However, designing an arbitrary unitary transform is difficult physically,
so we are interested in finding some basic building blocks that can be combined into
anything, at least arbitrarily close enough.

A mathematically simple (although not necessarily physically easily realizable) universal gate set 
consists of only two gates: The Toffoli gate, and the Hadamard gate.
The Toffoli gate exist for classical logic can be seen as the following 3-bit classical operation:
$(a, b, c) \mapsto (a, b, (a \land b) \oplus c )$.
It negates the third bit, if the first two are set to true. 
For this reason, it's also called the "control-control-not" gate.
It is universal classically: Any classical computation can be expressed as a long enough chain of Toffoli gates.
The Hadamard gate can intuitively be seen as a basic single qubit "make a superposition" operation, 
so that provides the quantum magic, which is not possible classically. 
The Hadamard matrix is:
$\frac{1}{\sqrt{2}}\begin{pmatrix}1 & 1  \\ 1 & -1 \end{pmatrix}$
The Toffoli matrix is some permutation matrix for 3 bits, but for quantum computer
emulation, we need to be able to construct it controlled on any qubits, which there are more than 3.
So for now just consider the uncontrolled single qubit not (invertor) matrix:
$\begin{pmatrix}0 & 1  \\ 1 & 0 \end{pmatrix}$.
We will also need a no-op representation, which is unexpectedly given by the identity matrix:
$\begin{pmatrix}1 & 0  \\ 0 & 1 \end{pmatrix}$.


# Sequential execution
This one is easy. Consider we already have some operations $A$ and $B$ and have their matrices.
Then running $B$ after $A$ corresponds to the operation given my the matrix product $B\cdot A$.

In numpy, this is the `dot` operation or simply using the `@` matmul overload.

# Parallel execution
When we want to run two or more quantum gates at the same time (over dijsoint set of qubits)
the corresponding operation on all the qubits is given by the tensor product $A \otimes B$ of the corresponding matrices $A, B$.

In numpy, this is again the `np.kron` operation.

If using a universal gate set, we will often need to run the basic operations on just a few qubits
and do the no-op identity in parallel on the others. 

# Controlled execution
As seem from the Toffoli gate universality, controlled execution is crucial aspect of quantum circuit design.
Essentially, the matrix we want to find is the following:
Assuming a $n$-qubit circuit, provided a gate placed at given qubit(s), controlled by another given qubit,
obtain the matrix for this operation.
There is en efficient [explicit construction](https://quantumcomputing.stackexchange.com/questions/37293/what-is-the-formula-for-the-matrix-representation-of-a-general-controlled-gate) to do that, but it's a bit more complicated to implement, so
in my implementation I went for the following (rather inefficient) trick instead:
First make the uncontrolled matrix $U$ (using the parallel execution with no-op as explained above).
Construct the controlled matrix column-wise: 
For each of the possible $2^n$ basis vectors $e_i$ (i.e. classical bit values), if the control bit(s) is(are) true,
use $Ue_i$ as the column, otherwise, use $e_i$. 

# Emulating observation
The above is all there is necessary to emulate the quantum state evolution.
We then finish the computation by collapsing the quantum superpositions and entanglements and observing the classical bits.

The [Born rule](https://en.wikipedia.org/wiki/Born_rule) tells us we should take the vector $\psi$ representing the qubit array
and calculate $|\psi|^2$ elementwise. 
This reduces the complex number representing the quantum state to a probability distribution over classical bits, forgetting half the DoF.

We can take that as-is or sample answers. 

And there you have it. It's just a bunch of linear algebra. But given the exponential size  of the representation, it's obvious why this is difficult.

# References

1. _Linear algebraic proof of Wigner theorem and its consequences_, Barvínek J., Hamhalter J.; Mathematica Slovaca Vol. 67, Issue 2. (2017)

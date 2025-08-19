![IHP Badge](https://img.shields.io/badge/IHP-Institute%20for%20High%20Performance%20Microelectronics-blue?style=for-the-badge&logo=researchgate&logoColor=white)
![OPENROAD Badge](https://img.shields.io/badge/OpenROAD-EDA%20Flow-orange?style=for-the-badge&logo=roadmap&logoColor=white)
![FOSSEE Badge](https://img.shields.io/badge/FOSSEE-Open%20Source%20EDA-green?style=for-the-badge&logo=github&logoColor=white)

# 💻📐CORDIC SINE/COSINE GENERATOR using IHP SG13G2 BiCMOS PDK 
---

## 📌 Introduction

The **CORDIC (COordinate Rotation DIgital Computer)** algorithm is an efficient hardware-friendly iterative method used to compute a wide range of functions including trigonometric, hyperbolic, exponential, logarithmic, and square-root operations. Traditional computation of trigonometric functions requires multipliers, which are costly in terms of hardware. CORDIC eliminates the need for multipliers by using only **shift-add operations**, making it very efficient for FPGA and ASIC designs.  
- **Advantages:**  
  - Multiplier-less implementation  
  - Low hardware complexity  
  - Scalable precision  
  - Ideal for embedded systems, DSPs, and processors  

---

## 📌 Mathematical Modelling

The CORDIC algorithm is based on iterative **vector rotations** using predefined elementary angles.  

### Rotation Equations

For a given vector `(x, y)`, rotated by an angle `z`:

```
x_{i+1} = x_i - d_i * (y_i >> i)
y_{i+1} = y_i + d_i * (x_i >> i)
z_{i+1} = z_i - d_i * atan(2^{-i})
```

Where:  
- `d_i ∈ {+1, -1}` is the direction of rotation  
- `>> i` means right shift (equivalent to division by `2^i`)  

The algorithm converges to compute:

```
cos(θ) ≈ x_n / K
sin(θ) ≈ y_n / K
```

Here, `K` is a scaling factor:

```
K = ∏ ( 1 / sqrt(1 + 2^{-2i}) )
```

This constant can be precomputed.

---

## 📌 Methodology

To implement a **CORDIC Sine/Cosine Generator in Verilog**, we divide the design into the following blocks:

1. **Controller Block**  
   - Controls the iteration count  
   - Provides direction (`d_i`) for rotation  

2. **Shift-Add Unit**  
   - Performs shifting and adding operations for `x` and `y` updates  

3. **Angle LUT (Look-Up Table)**  
   - Stores precomputed `atan(2^-i)` values  

4. **Top Module**  
   - Integrates all submodules  
   - Outputs sine and cosine values  

---

## 📌 Implementation

The **CORDIC core** will be implemented in Verilog with the following modules:

- `cordic.v` → Main CORDIC implementation  
- `controller.v` → Controls iterations and direction  
- `lut.v` → Stores arctan values  
- `cordic_top.v` → Top-level integration module  

📂 Repository Structure:

```
CORDIC-SINE-COSINE-Generator/
│── src/
│   ├── cordic.v
│   ├── controller.v
│   ├── lut.v
│   ├── cordic_top.v
│
│── tb/
│   ├── cordic_tb.v
│
│── docs/
│   ├── mathematical_model.md
│   ├── methodology.md
│
│── README.md
```

---

## 📌 Verification

- **Testbench (`cordic_tb.v`)** will verify:  
  1. Rotation mode correctness  
  2. Computed sine/cosine values against reference  
  3. Iterative convergence accuracy  

- Simulation can be done using:  
  - **Icarus Verilog**  
  - **ModelSim**  
  - **GTKWave** for waveform visualization  

Expected waveforms:  
- Input: angle `θ`  
- Outputs: `sin(θ)` and `cos(θ)` converging over iterations  

---

## 📌 Conclusion

- The **CORDIC-based sine/cosine generator** provides an efficient multiplier-less solution for trigonometric computations.  
- Expected Results:  
  - Accurate sine and cosine values with limited hardware usage  
  - Scalable precision based on number of iterations  
- Applications:  
  - Digital Signal Processing (DSP)  
  - FPGA/ASIC designs  
  - Embedded processors  

---

## 📚 References

1. Volder, J. E. (1959). "The CORDIC trigonometric computing technique." *IRE Transactions on Electronic Computers*  
2. Andraka, R. (1998). "A survey of CORDIC algorithms for FPGA based computers." *ACM/SIGDA*  
3. [CORDIC Algorithm - Wikipedia](https://en.wikipedia.org/wiki/CORDIC)  
4. [FPGA4Student - CORDIC in Verilog](https://www.fpga4student.com/)  

---


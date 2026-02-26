# Dual-Core Processor Architecture

> Developed by *Sara Ghazavi*
> Sharif University of Technology – Spring 1404

---

## 📝 Description

This project implements a **simplified dual-core processor architecture** inspired by **multi-cycle CPU design principles**.
It was developed as a course project for *Computer Architecture (CA)* at **Sharif University of Technology**.

The processor consists of **two parallel cores**, each with its own **ALU**, **Control Unit**, **Register File**, and **Program Counter**, sharing a **common data memory** managed through concurrency control.
The goal of this project was to explore the fundamentals of **hardware–software parallelism**, **synchronization**, and **multi-core performance evaluation**.

---

## ⚙️ Features

✅ **Dual-Core Execution** — Two cores execute instructions concurrently.

✅ **Shared Data Memory** — Central memory accessible by both cores with concurrency control.

✅ **Custom Instruction Set** — Includes special synchronization instructions:

* `cpuid` – Identifies the executing core
* `sync` – Enforces instruction ordering
* `exchng` – Atomic memory exchange

  ✅ **Spinlock Mechanism** — Prevents race conditions in shared memory access.
  
  ✅ **Performance Evaluation** — Parallel execution tested on 8×8 matrix multiplication and summation benchmarks.
  
  ✅ **Instruction-Level Parallelism** — Demonstrated through concurrent load/store and ALU operations.

---

## 🧩 Architecture Overview

```
+-----------------------------+
|        Shared Memory        |
+-----------------------------+
          ↑          ↑
   +-------------+  +-------------+
   |   Core #1   |  |   Core #2   |
   |-------------|  |-------------|
   | ALU         |  | ALU         |
   | Control Unit|  | Control Unit|
   | Reg File    |  | Reg File    |
   | PC          |  | PC          |
   +-------------+  +-------------+
```

Each core executes instructions independently, synchronizing via shared memory using atomic operations and a spinlock-based protocol.

---

## 🛠️ Technical Stack

* **Language:** Verilog
* **Simulation Tools:** ModelSim / Quartus
* **Architecture:** Multi-cycle dual-core CPU
* **Synchronization:** Custom ISA extensions (`cpuid`, `sync`, `exchng`)
* **Memory:** Shared data memory with concurrency control

---

## 📘 Educational Objectives

* Understand the fundamentals of **multi-core processor design**
* Learn how **concurrency and synchronization** work at the hardware level
* Implement **custom instruction sets** and **control logic**
* Explore **hardware-level performance improvements** through parallel execution.

---

## 👩‍💻 Author

**Sara Ghazavi**
Sharif University of Technology
Course: Computer Architecture – Spring 1404

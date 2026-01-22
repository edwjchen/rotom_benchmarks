# Rotom Benchmarks

This directory contains benchmark suites for evaluating [Rotom](https://github.com/cmu-cryptosystems/Rotom)'s homomorphic encryption compiler. The benchmarks are organized into two categories: **FHELIPE benchmarks** and **Viaduct benchmarks**, representing circuits compiled by different FHE compilers that Rotom can execute.

## FHELIPE Benchmarks

FHELIPE benchmarks are provided as directories containing the compiled circuit representation from the FHELIPE compiler. Each benchmark directory contains:

- **`rt.df`**: Runtime dataflow file containing the circuit operations
- **`enc.cfg/`**: Directory with layout configuration files for each input/output
- **`ch_ir/`**: Directory with plaintext (ciphertext) intermediate representation files

## Viaduct Benchmarks

Viaduct benchmarks are provided as `.vhe` (Viaduct Homomorphic Encryption) files containing the compiled circuit representation from the Viaduct compiler. These files contain a high-level representation of the FHE circuit operations.

## Related Documentation

For more information about:
- Rotom architecture and usage: See `Rotom/README.md`
- Wrapper implementation: See `Rotom/wrappers/fhelipe_wrapper.py` and `Rotom/wrappers/viaduct_wrapper.py`

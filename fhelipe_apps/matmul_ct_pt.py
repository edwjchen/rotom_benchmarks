import tensorfhe as tfhe


class Matmul_Ct_Pt(tfhe.App):
    def __init__(self, n: int = 128, m: int = 64, **kwargs):
        a = tfhe.tensor("a", (n, m))
        b = tfhe.public_in("b", (m, n))
        result = tfhe.lib.mmul(a, b)
        super().__init__(id=(n, m), out=result)


if __name__ == "__main__":
    Matmul_Ct_Pt.main()

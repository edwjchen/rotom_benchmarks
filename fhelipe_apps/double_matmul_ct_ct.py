import tensorfhe as tfhe


class Double_Matmul_Ct_Ct(tfhe.App):
    def __init__(self, n: int = 128, m: int = 64, **kwargs):
        a = tfhe.tensor("a", (n, m))
        b = tfhe.tensor("b", (m, n))
        c = tfhe.tensor("c", (n, m))
        result = tfhe.lib.mmul(a, b)
        result = tfhe.lib.mmul(result, c)
        super().__init__(id=(n, m), out=result)


if __name__ == "__main__":
    Double_Matmul_Ct_Ct.main()

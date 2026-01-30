import tensorfhe as tfhe


class MatVecMul(tfhe.App):
    def __init__(self, **kwargs):
        a = tfhe.tensor("a", (197,))
        b = tfhe.public_in("b", (1024, 197))
        c = tfhe.public_in("c", (197, 1024))
        result = tfhe.lib.mul_mv(b, a)
        result = tfhe.lib.mul_mv(c, result)
        super().__init__(id=(32), out=result)


if __name__ == "__main__":
    MatVecMul.main()

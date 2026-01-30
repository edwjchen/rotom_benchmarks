import tensorfhe as tfhe


class Attention(tfhe.App):
    def __init__(self, n: int = 128, m: int = 768, **kwargs):
        H = tfhe.tensor("H", (n, m))
        Wq = tfhe.public_in("Wq", (m, m))
        Wk = tfhe.public_in("Wk", (m, m))
        Wv = tfhe.public_in("Wv", (m, m))
        Bq = tfhe.public_in("Bq", (m,))
        Bk = tfhe.public_in("Bk", (m,))
        Bv = tfhe.public_in("Bv", (m,))

        rep_bq = Bq.replicate(dim=0, n=n)
        rep_bk = Bk.replicate(dim=0, n=n)
        rep_bv = Bv.replicate(dim=0, n=n)

        Q = tfhe.lib.mmul(H, Wq) + rep_bq
        K = tfhe.lib.mmul(H, Wk) + rep_bk
        V = tfhe.lib.mmul(H, Wv) + rep_bv
        S = tfhe.lib.mmul(Q, K.T)
        result = tfhe.lib.mmul(S, V)
        super().__init__(id=((n, m)), out=result)


if __name__ == "__main__":
    Attention.main()

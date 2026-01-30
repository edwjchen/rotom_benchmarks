import tensorfhe as tfhe


class Conv(tfhe.App):
    def __init__(self, **kwargs):
        img = tfhe.tensor("img", (8, 32, 32))
        weights = tfhe.public_in("img", (1, 1, 3, 3))
        result = tfhe.lib.conv2d(img, weights)
        super().__init__(id=(32), out=result)


if __name__ == "__main__":
    Conv.main()

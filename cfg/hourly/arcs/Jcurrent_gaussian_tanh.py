import typing as T
import numpy as np


def Jcurrent_gaussian_tanh(E: dict[str, T.Any], Nt: int, gridflag: int, flagdip: bool):
    """
    Set the top boundary shape (current density) and potential solve type
    flag.  Can be adjusted by user to achieve any desired shape.
    """

    Jpk = E["Jtarg"]

    displace = 10 * E["mlatsig"]
    mlatctr = E["mlatmean"] + displace * np.tanh((E["MLON"] - E["mlonmean"]) / (2 * E["mlonsig"]))
    # changed so the arc is wider compared to its twisting
    for i in range(Nt):
        E["flagdirich"][i] = 0
        E["Vminx1it"][i, :, :] = np.zeros((E["llon"], E["llat"]))
        if i > 2:
            E["Vmaxx1it"][i, :, :] = (
                Jpk
                * np.exp(-((E["MLON"] - E["mlonmean"]) ** 2) / 2 / E["mlonsig"] ** 2)
                * np.exp(-((E["MLAT"] - mlatctr - 1.5 * E["mlatsig"]) ** 2) / 2 / E["mlatsig"] ** 2)
            )
            E["Vmaxx1it"][i, :, :] = E["Vmaxx1it"][i, :, :] - Jpk * np.exp(
                -((E["MLON"] - E["mlonmean"]) ** 2) / 2 / E["mlonsig"] ** 2
            ) * np.exp(-((E["MLAT"] - mlatctr + 1.5 * E["mlatsig"]) ** 2) / 2 / E["mlatsig"] ** 2)
        else:
            E["Vmaxx1it"][i, :, :] = np.zeros((E["llon"], E["llat"]))

    return E

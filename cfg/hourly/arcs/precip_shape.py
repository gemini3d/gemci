import numpy as np
import typing as T


def precip_shape(pg: dict[str, T.Any], Qpeak: float, Qbackground: float) -> np.ndarray:
    """
    makes a 2D Gaussian shape in Latitude, Longitude
    """

    displace = 10 * pg["mlat_sigma"]

    mlatctr = pg["mlat_mean"] + displace * np.tanh(
        (pg["MLON"] - pg["mlon_mean"]) / (2 * pg["mlon_sigma"])
    )
    # changed so the arc is wider compared to its twisting

    S = np.exp(-((pg["MLON"] - pg["mlon_mean"]) ** 2) / 2 / pg["mlon_sigma"] ** 2) * np.exp(
        -((pg["MLAT"] - mlatctr - 1.5 * pg["mlat_sigma"]) ** 2) / 2 / pg["mlat_sigma"] ** 2
    )
    Q = Qpeak * S

    Q[Q < Qbackground] = Qbackground

    return Q

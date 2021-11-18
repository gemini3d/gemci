import numpy as np
import xarray


def precip_shape(pg: xarray.Dataset, Qpeak: float, Qbackground: float) -> np.ndarray:
    """
    makes a 2D Gaussian shape in Latitude, Longitude
    """

    mlon_mean = pg.mlon.mean().item()
    mlat_mean = pg.mlat.mean().item()

    displace = 10 * pg.mlat_sigma

    mlatctr = mlat_mean + displace * np.tanh((pg.mlon.data - mlon_mean) / (2 * pg.mlon_sigma))
    # changed so the arc is wider compared to its twisting

    [MLON,MLAT]=np.meshgrid(pg.mlon.data,pg.mlat.data)

    S = np.exp(-((MLON - mlon_mean) ** 2) / 2 / pg.mlon_sigma ** 2) * np.exp(
        -((MLAT - mlatctr - 1.5 * pg.mlat_sigma) ** 2) / 2 / pg.mlat_sigma ** 2
    )
    Q = Qpeak * S

    Q[Q < Qbackground] = Qbackground

    return Q

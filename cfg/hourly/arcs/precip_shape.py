import numpy as np
import xarray


def precip_shape(pg: xarray.Dataset, Qpeak: float, Qbackground: float) -> xarray.DataArray:
    """
    makes a 2D Gaussian shape in Latitude, Longitude
    """

    mlon_mean = pg.mlon.mean().item()
    mlat_mean = pg.mlat.mean().item()

    displace = 10 * pg.mlat_sigma

    mlatctr = mlat_mean + displace * np.tanh((pg.mlon - mlon_mean) / (2 * pg.mlon_sigma))
    # changed so the arc is wider compared to its twisting
    Q = (
        Qpeak
        * np.exp(-((pg.mlon - mlon_mean) ** 2) / 2 / pg.mlon_sigma ** 2)
        * np.exp(-((pg.mlat - mlatctr - 1.5 * pg.mlat_sigma) ** 2) / 2 / pg.mlat_sigma ** 2)
    )

    return Q.clip(min=Qbackground)

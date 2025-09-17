import matplotlib as mpl
mpl.rcParams["figure.raise_window"] = False
import matplotlib.pyplot as plt
import numpy as np

def get_or_create_fig(num, **kwargs):
    """
    Get an existing figure by number, or create a new one if it does not exist.

    Parameters
    ----------
    num : int or str
        Figure number or label. If a figure with this number already exists,
        it will be returned. Otherwise, a new figure is created.
    **kwargs :
        Additional keyword arguments are passed to plt.figure when creating
        a new figure (e.g., figsize, dpi).

    Returns
    -------
    fig : matplotlib.figure.Figure
        The existing or newly created figure.
    """
    if plt.fignum_exists(num):
        # If a figure with this number already exists, just return it.
        fig = plt.figure(num)
    else:
        # Otherwise, create a new figure with the given kwargs.
        fig = plt.figure(num, **kwargs)
    return fig

def get_or_create_subplots(num=1, *args, **kwargs):
    """
    Like plt.subplots, but if a figure with the given number already exists,
    reuse it and clear it, otherwise create it fresh.

    Parameters
    ----------
    num : int or str
        Figure number or label.
    *args, **kwargs :
        Passed to plt.subplots when creating a new figure.

    Returns
    -------
    fig, ax : Figure and Axes (or array of Axes)
    """
    if plt.fignum_exists(num):
        fig = plt.figure(num)
        ax = fig.gca()
    else:
        fig, ax = plt.subplots(num=num, *args, **kwargs)
    return fig, ax
    

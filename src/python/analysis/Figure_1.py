###############################################
# Based on the MIMIC-Extract repository:
# hhttps://github.com/MLforHealth/MIMIC_Extract
#
# Original file:
# MIMIC-Extract/notebooks/Summary Stats.ipynb
#
# Accessed: 21 August 2026
#
# Modifications compared to original file:
# 
# 
#
# TO DO:
# 
#############################


import numpy as np
import pandas as pd
from scipy.stats import ttest_ind_from_stats, spearmanr
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt
%matplotlib inline



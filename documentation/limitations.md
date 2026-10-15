# Limitations
- Synthetic data: patterns are designed, so results demonstrate the method, not real warehouse behaviour.
- The risk score uses same-period variance history, so its coverage of variance value is partly circular; see the holdout check in findings.
- Weights and thresholds are starting assumptions.
- Chi-square tests are uncorrected and exploratory.
- The weekly accuracy decline is a data-generation effect.
- Power Query/DAX untested in Power BI Desktop; no .pbix included.

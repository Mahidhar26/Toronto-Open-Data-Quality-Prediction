# Toronto Open Data Quality Prediction

Welcome to the repository for the **Open Data Quality Prediction** project. This project analyzes and predicts the quality grade (Gold, Silver, Bronze) of datasets published on the City of Toronto's Open Data Portal. It employs a suite of machine learning techniques to identify quality drivers, build predictive models, and generate interpretable insights to assist data governance efforts.

---

## Project Objective

The core goal of this project is to build a framework that:

* Predicts dataset quality grades using multiple machine learning algorithms
* Identifies which attributes (e.g., metadata, freshness) most influence these grades
* Produces human-understandable explanations for classification outcomes
* Supports integration into dashboards and policy feedback loops for public sector use

---

## Questions Asked

1. Can we accurately predict the quality grade of a dataset using its metadata and related attributes?
2. Which features (e.g., usability, completeness, freshness) are most predictive of high-quality (Gold) vs. low-quality (Bronze) datasets?
3. Do different modeling techniques agree on key predictors?
4. Can we extract interpretable rules for decision-making?
5. Can these models be implemented in real-time dashboards?

---

## Dataset

The dataset, sourced from the **City of Toronto Open Data Portal**, contains over 100,000 records describing dataset quality across five core metrics:

* **Usability**
* **Metadata**
* **Freshness**
* **Completeness**
* **Accessibility**

Each record also includes the dataset's assigned **grade** (Gold, Silver, Bronze), division, and other attributes.

After cleaning, the final working dataset contained **55,748** high-quality rows.

---

## 🧠 Modeling Techniques Used

### 1. Multinomial Logistic Regression

* **Purpose**: Establish a baseline model that estimates probabilities of Gold, Silver, and Bronze.
* **Outcome**: Achieved 85–90% accuracy. Showed strong influence of usability and completeness.

### 2. Decision Tree (with Penalty Matrix)

* **Purpose**: Generate clear, rule-based explanations for predictions.
* **Outcome**: Accuracy of \~98.9%. Penalty matrix reduced misclassification of Bronze as Gold. Rules such as:

  * *If metadata < 0.64 and freshness < 0.39 → Bronze*
  * *If metadata ≥ 0.99 and freshness ≥ 0.74 → Gold*

### 3. Random Forest (Tuned with 200 Trees)

* **Purpose**: Improve prediction accuracy and feature robustness.
* **Outcome**: Accuracy of \~97.7%. Identified metadata and freshness as top features. Handled variance across service groups.

### 4. Support Vector Machines (SVM)

* **Purpose**: Model complex, non-linear relationships using RBF kernel.
* **Outcome**: High classification accuracy with strong separation for Bronze datasets. Some overlap between Silver and Gold.

### 5. Linear Discriminant Analysis (LDA)

* **Purpose**: Visualize linear separability between classes and reduce dimensions.
* **Outcome**: Accuracy \~95.8%. Metadata had the strongest influence. Discriminant plots clearly separated Bronze.

### 6. K-Means Clustering with PCA

* **Purpose**: Discover natural clusters and verify label structure.
* **Outcome**: Identified 3 distinct clusters corresponding to Gold, Silver, and Bronze. Validated using elbow and silhouette scores.

---

## Explainability Tools

* **SHAP (Shapley Values)**: Provided global and local interpretability, confirming metadata and freshness as primary drivers.
* **LIME**: Offered per-instance feature explanations, supporting transparency for dashboard users.

---

## Implementation Highlights

* Used `rpart`, `randomForest`, `nnet`, `e1071`, `MASS`, and `caret` packages in R.
* Applied a custom **penalty matrix** in the Decision Tree to reduce high-risk misclassifications.
* Trained Random Forest with **200 trees** and performed `mtry` tuning via cross-validation.
* Exported the final dataset for Power BI dashboard integration.

---

## Goals Achieved

* Built multiple models to classify dataset quality with high accuracy
* Identified key features for strategic improvement (metadata, freshness)
* Extracted decision rules and visualized model logic for non-technical users
* Provided recommendations for improving data quality governance by service group
* Enabled model integration into dashboards and REST APIs

---

## Future Work

* Integrate time-series modeling to assess freshness decay
* Use feedback loops to incorporate user trust and usage metrics
* Automate real-time quality alerts for new datasets

---

## 📂 Folder Structure

```
├── data/                  # Raw and cleaned data
├── scripts/               # R scripts for modeling and EDA
├── outputs/               # Plots, model outputs, rules
├── decision_tree_rules.txt
├── dataset_quality_powerbi.csv
└── README.md              # This file
```

---



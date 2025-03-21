# Step 1: Load Required Libraries
library(dplyr)
library(ggplot2)
library(caret)
library(cluster)
library(arules)
library(corrplot)
library(lattice)
library(Matrix)
library(reshape2)  # For melting the correlation matrix

# Step 2: Load Your Dataset
# Replace the file path with the correct location of your CSV file
data <- read.csv("Teravel tourism and tourist in Iran.csv", stringsAsFactors = TRUE)

# Quickly inspect the dataset
head(data)
str(data)
summary(data)

# Step 3: Data Cleaning (if needed)
# Check for missing values in each column
colSums(is.na(data))
# (You can choose to impute or remove missing rows as needed.)

# Step 4: Basic Visualization with ggplot2
# Example: Bar plot of average tourism ('Avg') by province
ggplot(data, aes(x = province, y = Avg)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Average Tourism by Province", x = "Province", y = "Average Tourism")


# Step 5: Correlation Analysis of Numeric Variables
# Select numeric columns; adjust these names/indexes if your dataset differs.
num_data <- data %>% 
  select(ecotourism, Caravanserai, Museum, Historical.mosque, Church, 
         Castle, Lake, waterfall, River, dam, Forest, desert, plain, 
         mountainous, Sea, port, Beach, Traditional.market, 
         UNESCO.registration, Protected.area, Flight.site, 
         ski.slope, Island, X2015...2018, X2019...2021, Avg) %>%
  mutate(across(everything(), as.numeric))  # Convert all to numeric

# Compute the correlation matrix (using complete observations)
cor_mat <- cor(num_data, use = "complete.obs")

# Visualize the correlation matrix using corrplot
corrplot(cor_mat, method = "color", type = "upper", tl.col = "black", tl.srt = 45)

# Alternatively, visualize the correlation matrix with ggplot2
cor_melt <- melt(cor_mat)
ggplot(cor_melt, aes(x = Var1, y = Var2, fill = value)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "dodgerblue3", mid = "white", high = "firebrick3", midpoint = 0) +
  theme_minimal() +
  labs(title = "Correlation Matrix", x = "", y = "") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Step 6: Clustering Analysis
# Scale numeric data for clustering
num_data_scaled <- scale(num_data)

# Determine an optimal number of clusters using the elbow method
wss <- sapply(1:10, function(k) {
  kmeans(num_data_scaled, centers = k, nstart = 25)$tot.withinss
})
plot(1:10, wss, type = "b", pch = 19, frame = FALSE,
     xlab = "Number of Clusters (K)",
     ylab = "Total Within-Cluster Sum of Squares",
     main = "Elbow Method for Optimal K")

# Suppose the elbow suggests 3 clusters; run k-means clustering
set.seed(123)
km_res <- kmeans(num_data_scaled, centers = 3, nstart = 25)
data$cluster <- as.factor(km_res$cluster)  # add cluster labels to the dataset

# Visualize the clusters using PCA (first two principal components)
pca_res <- prcomp(num_data_scaled)
pca_data <- data.frame(PC1 = pca_res$x[,1],
                       PC2 = pca_res$x[,2],
                       cluster = data$cluster)
ggplot(pca_data, aes(x = PC1, y = PC2, color = cluster)) +
  geom_point(size = 3) +
  theme_minimal() +
  labs(title = "Clustering Results (PCA Plot)", x = "PC1", y = "PC2")
# ----------------------TEST----------------------

# Load necessary library for association rule mining
library(arules)

# Step 7: Association Rule Mining on Categorical Data
# Select categorical columns (e.g., province, climate, and Location)
cat_data <- data %>% select(province, climate, Location)

# Convert each row into a list of categorical values
trans_list <- split(cat_data, seq(nrow(cat_data)))

# Convert each element of the list into character format
trans_list <- lapply(trans_list, as.character)

# Convert to transactions
transactions <- as(trans_list, "transactions")

# Check the structure
summary(transactions)
# ------------------------------------------------


# Run the apriori algorithm; adjust 'supp' and 'conf' thresholds as needed
rules <- apriori(transactions, parameter = list(supp = 0.1, conf = 0.8))
inspect(rules)

# Step 8: Predictive Modeling using caret
# Example: Predict 'Avg' using a set of numeric predictors

# Split data into training (80%) and testing (20%)
set.seed(123)
train_index <- createDataPartition(data$Avg, p = 0.8, list = FALSE)
train_data <- data[train_index, ]
test_data  <- data[-train_index, ]

# Build a linear regression model using caret
model <- train(Avg ~ ecotourism + Caravanserai + Museum + Historical.mosque +
                 Church + Castle + Lake + waterfall + River + dam + Forest +
                 desert + plain + mountainous + `port` + Beach +
                 `Traditional.market` + UNESCO.registration + Protected.area +
                 `Flight.site` + `ski.slope` + Island + X2015...2018 + X2019...2021,
               data = train_data,
               method = "lm")
print(model)

# Predict on the test set and evaluate the model
predictions <- predict(model, newdata = test_data)
performance <- postResample(predictions, test_data$Avg)
print(performance)

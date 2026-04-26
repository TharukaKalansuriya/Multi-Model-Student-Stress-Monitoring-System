"""
Random Forest Model Training Script for UCI HAR Dataset

This script:
1. Loads UCI HAR Dataset (Train/Test split)
2. Trains a Random Forest Classifier
3. Evaluates model performance
4. Saves the trained model for use in physical activity analysis

Dataset Structure:
- X_train.txt: 7,352 samples × 561 features
- y_train.txt: 7,352 activity labels (1-6)
- X_test.txt: 2,947 samples × 561 features
- y_test.txt: 2,947 activity labels

Activities:
1 = WALKING
2 = WALKING_UPSTAIRS
3 = WALKING_DOWNSTAIRS
4 = SITTING
5 = STANDING
6 = LAYING

Author: Student Stress App Training Pipeline
Date: April 2026
"""

import os
import numpy as np
from pathlib import Path
import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score, 
    precision_score, 
    recall_score, 
    f1_score,
    confusion_matrix,
    classification_report
)
import time


class UCIHARRandomForestTrainer:
    """Train and evaluate Random Forest model on UCI HAR dataset"""
    
    # Activity labels mapping
    ACTIVITIES = {
        1: 'WALKING',
        2: 'WALKING_UPSTAIRS',
        3: 'WALKING_DOWNSTAIRS',
        4: 'SITTING',
        5: 'STANDING',
        6: 'LAYING'
    }
    
    def __init__(self, dataset_path: str, model_output_path: str):
        """
        Initialize trainer
        
        Args:
            dataset_path: Path to UCI-HAR Dataset folder
            model_output_path: Path to save trained model
        """
        self.dataset_path = Path(dataset_path)
        self.model_output_path = Path(model_output_path)
        
        # Ensure output directory exists
        self.model_output_path.mkdir(parents=True, exist_ok=True)
        
        print("[*] UCI HAR Random Forest Trainer initialized")
        print(f"    Dataset path: {self.dataset_path}")
        print(f"    Model output path: {self.model_output_path}")
    
    def load_dataset(self) -> tuple:
        """
        Load UCI HAR Dataset
        
        Returns:
            (X_train, y_train, X_test, y_test) - Training and test data
        """
        print("\n[*] Loading UCI HAR Dataset...")
        
        # Training data paths
        X_train_path = self.dataset_path / "train" / "X_train.txt"
        y_train_path = self.dataset_path / "train" / "y_train.txt"
        
        # Test data paths
        X_test_path = self.dataset_path / "test" / "X_test.txt"
        y_test_path = self.dataset_path / "test" / "y_test.txt"
        
        # Verify files exist
        for path in [X_train_path, y_train_path, X_test_path, y_test_path]:
            if not path.exists():
                raise FileNotFoundError(f"Dataset file not found: {path}")
        
        # Load data
        print("    Loading training data...")
        X_train = np.loadtxt(X_train_path)
        y_train = np.loadtxt(y_train_path, dtype=int)
        
        print("    Loading test data...")
        X_test = np.loadtxt(X_test_path)
        y_test = np.loadtxt(y_test_path, dtype=int)
        
        print(f"[OK] Dataset loaded successfully")
        print(f"    Training samples: {X_train.shape[0]} × {X_train.shape[1]} features")
        print(f"    Test samples: {X_test.shape[0]} × {X_test.shape[1]} features")
        print(f"    Activity classes: {len(np.unique(y_train))}")
        
        return X_train, y_train, X_test, y_test
    
    def train_model(self, X_train: np.ndarray, y_train: np.ndarray) -> RandomForestClassifier:
        """
        Train Random Forest Classifier
        
        Args:
            X_train: Training features (n_samples × 561)
            y_train: Training labels (activity 1-6)
        
        Returns:
            Trained RandomForestClassifier model
        """
        print("\n[*] Training Random Forest Classifier...")
        print("    Hyperparameters:")
        print("    - n_estimators: 100 trees")
        print("    - max_depth: 20")
        print("    - min_samples_split: 5")
        print("    - min_samples_leaf: 2")
        print("    - n_jobs: -1 (use all CPU cores)")
        
        start_time = time.time()
        
        # Create and train model
        model = RandomForestClassifier(
            n_estimators=100,           # Number of trees
            max_depth=20,               # Max tree depth
            min_samples_split=5,        # Min samples to split node
            min_samples_leaf=2,         # Min samples in leaf node
            random_state=42,            # For reproducibility
            n_jobs=-1,                  # Use all CPU cores
            verbose=1                   # Show progress
        )
        
        model.fit(X_train, y_train)
        
        elapsed_time = time.time() - start_time
        
        print(f"[OK] Model training completed in {elapsed_time:.2f} seconds")
        
        return model
    
    def evaluate_model(self, model: RandomForestClassifier, 
                      X_test: np.ndarray, y_test: np.ndarray) -> dict:
        """
        Evaluate model performance on test set
        
        Args:
            model: Trained RandomForestClassifier
            X_test: Test features
            y_test: Test labels
        
        Returns:
            Dictionary with evaluation metrics
        """
        print("\n[*] Evaluating model on test set...")
        
        # Make predictions
        y_pred = model.predict(X_test)
        
        # Calculate metrics
        accuracy = accuracy_score(y_test, y_pred)
        precision = precision_score(y_test, y_pred, average='weighted')
        recall = recall_score(y_test, y_pred, average='weighted')
        f1 = f1_score(y_test, y_pred, average='weighted')
        
        print(f"\n[RESULTS] Model Performance Metrics:")
        print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(f"  Accuracy:  {accuracy:.4f} ({accuracy*100:.2f}%)")
        print(f"  Precision: {precision:.4f}")
        print(f"  Recall:    {recall:.4f}")
        print(f"  F1-Score:  {f1:.4f}")
        print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        # Confusion matrix
        print(f"\n[*] Confusion Matrix:")
        cm = confusion_matrix(y_test, y_pred)
        print(cm)
        
        # Per-class performance
        print(f"\n[*] Per-Activity Performance:")
        print(classification_report(y_test, y_pred, 
                                   target_names=[self.ACTIVITIES[i] for i in range(1, 7)]))
        
        return {
            'accuracy': accuracy,
            'precision': precision,
            'recall': recall,
            'f1_score': f1,
            'confusion_matrix': cm,
            'y_pred': y_pred,
            'y_test': y_test
        }
    
    def save_model(self, model: RandomForestClassifier, model_name: str = "uci_har_random_forest.pkl"):
        """
        Save trained model to disk
        
        Args:
            model: Trained RandomForestClassifier
            model_name: Output filename
        """
        print(f"\n[*] Saving model to disk...")
        
        model_path = self.model_output_path / model_name
        joblib.dump(model, model_path, compress=3)
        
        file_size_mb = model_path.stat().st_size / (1024 * 1024)
        
        print(f"[OK] Model saved successfully")
        print(f"    Path: {model_path}")
        print(f"    Size: {file_size_mb:.2f} MB")
        
        return model_path
    
    def save_model_info(self, model: RandomForestClassifier, metrics: dict, 
                       info_filename: str = "model_info.txt"):
        """
        Save model information and performance metrics
        
        Args:
            model: Trained model
            metrics: Evaluation metrics
            info_filename: Output filename
        """
        print(f"\n[*] Saving model information...")
        
        info_path = self.model_output_path / info_filename
        
        with open(info_path, 'w') as f:
            f.write("=" * 70 + "\n")
            f.write("UCI HAR Random Forest Model - Information\n")
            f.write("=" * 70 + "\n\n")
            
            f.write("MODEL DETAILS\n")
            f.write("-" * 70 + "\n")
            f.write(f"Model Type: Random Forest Classifier\n")
            f.write(f"Number of Trees: {model.n_estimators}\n")
            f.write(f"Max Depth: {model.max_depth}\n")
            f.write(f"Min Samples Split: {model.min_samples_split}\n")
            f.write(f"Min Samples Leaf: {model.min_samples_leaf}\n")
            f.write(f"Random State: {model.random_state}\n\n")
            
            f.write("DATASET INFORMATION\n")
            f.write("-" * 70 + "\n")
            f.write(f"Dataset: UCI Human Activity Recognition Using Smartphones\n")
            f.write(f"Samples: Train=7,352, Test=2,947\n")
            f.write(f"Features: 561 (time + frequency domain)\n")
            f.write(f"Activities: 6 (WALKING, WALKING_UP, WALKING_DOWN, SITTING, STANDING, LAYING)\n")
            f.write(f"Sensors: Accelerometer + Gyroscope (3-axis each)\n")
            f.write(f"Sampling Rate: 50 Hz\n\n")
            
            f.write("PERFORMANCE METRICS\n")
            f.write("-" * 70 + "\n")
            f.write(f"Accuracy:  {metrics['accuracy']:.4f} ({metrics['accuracy']*100:.2f}%)\n")
            f.write(f"Precision: {metrics['precision']:.4f}\n")
            f.write(f"Recall:    {metrics['recall']:.4f}\n")
            f.write(f"F1-Score:  {metrics['f1_score']:.4f}\n\n")
            
            f.write("FEATURE INFORMATION\n")
            f.write("-" * 70 + "\n")
            f.write(f"Input: 561 features extracted from sensor signals\n")
            f.write(f"Output: Activity class (1-6)\n")
            f.write(f"Feature types:\n")
            f.write(f"  - Time domain: Mean, STD, Min, Max, Energy, Entropy, etc.\n")
            f.write(f"  - Frequency domain: FFT coefficients, spectral power, etc.\n")
            f.write(f"  - Angles: Between acceleration vectors and gravity\n\n")
            
            f.write("ACTIVITY LABELS\n")
            f.write("-" * 70 + "\n")
            for activity_id, activity_name in self.ACTIVITIES.items():
                f.write(f"  {activity_id}: {activity_name}\n")
            
            f.write("\n" + "=" * 70 + "\n")
            f.write("Model ready for deployment in physical activity stress analysis\n")
            f.write("=" * 70 + "\n")
        
        print(f"[OK] Model information saved: {info_path}")
    
    def generate_feature_importance(self, model: RandomForestClassifier, 
                                   top_n: int = 20):
        """
        Analyze and display feature importance
        
        Args:
            model: Trained model
            top_n: Number of top features to display
        """
        print(f"\n[*] Feature Importance Analysis:")
        print(f"    Top {top_n} most important features:")
        
        importances = model.feature_importances_
        indices = np.argsort(importances)[::-1]
        
        for i in range(min(top_n, len(importances))):
            feature_idx = indices[i]
            importance = importances[feature_idx]
            print(f"    {i+1:2d}. Feature {feature_idx:3d}: {importance:.6f}")
    
    def train_and_save(self):
        """
        Main pipeline: Load data → Train model → Evaluate → Save
        """
        print("\n" + "=" * 70)
        print("UCI HAR Random Forest Model Training Pipeline")
        print("=" * 70)
        
        try:
            # Load dataset
            X_train, y_train, X_test, y_test = self.load_dataset()
            
            # Train model
            model = self.train_model(X_train, y_train)
            
            # Evaluate
            metrics = self.evaluate_model(model, X_test, y_test)
            
            # Feature importance
            self.generate_feature_importance(model, top_n=15)
            
            # Save model
            model_path = self.save_model(model)
            
            # Save info
            self.save_model_info(model, metrics)
            
            print("\n" + "=" * 70)
            print("[SUCCESS] Model training pipeline completed!")
            print("=" * 70)
            print(f"\nModel saved at: {model_path}")
            print(f"Ready for deployment in physical activity stress analysis\n")
            
            return model, metrics
            
        except Exception as e:
            print(f"\n[ERROR] Training pipeline failed: {e}")
            import traceback
            traceback.print_exc()
            return None, None


def main():
    """Entry point for training script"""
    
    # Define paths
    dataset_path = r"D:\FYP\New folder\student_stress_app\assets\UCI-HAR Dataset"
    model_output_path = r"D:\FYP\New folder\student_stress_app\assets\models"
    
    # Create trainer
    trainer = UCIHARRandomForestTrainer(dataset_path, model_output_path)
    
    # Train and save
    model, metrics = trainer.train_and_save()


if __name__ == "__main__":
    main()

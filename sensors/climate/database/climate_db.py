#!/usr/bin/env python3
"""
Climate Database Operations

Handles all SQLite database operations for climate data storage,
including creating tables, logging readings, querying historical data,
and data export functionality.
"""

import sqlite3
import logging
import json
import csv
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from pathlib import Path


class ClimateDatabase:
    """SQLite database handler for climate data."""
    
    def __init__(self, db_path: str, retention_days: int = 30):
        """
        Initialize database connection and create tables if needed.
        
        Args:
            db_path: Path to SQLite database file
            retention_days: Number of days to retain historical data
        """
        self.db_path = db_path
        self.retention_days = retention_days
        self.logger = logging.getLogger(__name__)
        
        # Ensure database directory exists
        db_dir = Path(db_path).parent
        db_dir.mkdir(parents=True, exist_ok=True)
        
        # Initialize database
        self._init_database()
    
    def _init_database(self):
        """Create database tables if they don't exist."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # Create climate_readings table
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS climate_readings (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                        temperature_c REAL NOT NULL,
                        temperature_f REAL NOT NULL,
                        humidity REAL NOT NULL,
                        dew_point_c REAL,
                        heat_index_c REAL,
                        comfort_level TEXT
                    )
                """)
                
                # Create index on timestamp for faster queries
                cursor.execute("""
                    CREATE INDEX IF NOT EXISTS idx_timestamp 
                    ON climate_readings(timestamp)
                """)
                
                conn.commit()
                self.logger.info(f"Database initialized at {self.db_path}")
                
        except sqlite3.Error as e:
            self.logger.error(f"Failed to initialize database: {e}")
            raise
    
    def log_reading(self, temperature_c: float, temperature_f: float, humidity: float,
                    dew_point_c: Optional[float] = None, heat_index_c: Optional[float] = None,
                    comfort_level: Optional[str] = None) -> bool:
        """
        Log a climate reading to the database.
        
        Args:
            temperature_c: Temperature in Celsius
            temperature_f: Temperature in Fahrenheit
            humidity: Relative humidity percentage
            dew_point_c: Dew point in Celsius (optional)
            heat_index_c: Heat index in Celsius (optional)
            comfort_level: Comfort level classification (optional)
        
        Returns:
            True if successful, False otherwise
        """
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT INTO climate_readings 
                    (temperature_c, temperature_f, humidity, dew_point_c, heat_index_c, comfort_level)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (temperature_c, temperature_f, humidity, dew_point_c, heat_index_c, comfort_level))
                conn.commit()
                return True
                
        except sqlite3.Error as e:
            self.logger.error(f"Failed to log reading: {e}")
            return False
    
    def get_latest_reading(self) -> Optional[Dict]:
        """
        Get the most recent climate reading.
        
        Returns:
            Dictionary with reading data, or None if no readings exist
        """
        try:
            with sqlite3.connect(self.db_path) as conn:
                conn.row_factory = sqlite3.Row
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT * FROM climate_readings 
                    ORDER BY timestamp DESC 
                    LIMIT 1
                """)
                row = cursor.fetchone()
                
                if row:
                    return dict(row)
                return None
                
        except sqlite3.Error as e:
            self.logger.error(f"Failed to get latest reading: {e}")
            return None
    
    def get_historical_data(self, start_time: Optional[datetime] = None,
                           end_time: Optional[datetime] = None,
                           limit: int = 1000) -> List[Dict]:
        """
        Get historical climate data within a time range.
        
        Args:
            start_time: Start of time range (default: 24 hours ago)
            end_time: End of time range (default: now)
            limit: Maximum number of records to return
        
        Returns:
            List of reading dictionaries
        """
        try:
            if start_time is None:
                start_time = datetime.now() - timedelta(days=1)
            if end_time is None:
                end_time = datetime.now()
            
            with sqlite3.connect(self.db_path) as conn:
                conn.row_factory = sqlite3.Row
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT * FROM climate_readings 
                    WHERE timestamp BETWEEN ? AND ?
                    ORDER BY timestamp DESC
                    LIMIT ?
                """, (start_time.isoformat(), end_time.isoformat(), limit))
                
                rows = cursor.fetchall()
                return [dict(row) for row in rows]
                
        except sqlite3.Error as e:
            self.logger.error(f"Failed to get historical data: {e}")
            return []
    
    def get_statistics(self, period: str = 'day') -> Optional[Dict]:
        """
        Get aggregated statistics for a time period.
        
        Args:
            period: Time period ('day', 'week', 'month')
        
        Returns:
            Dictionary with min, max, avg for temperature and humidity
        """
        try:
            # Calculate time range
            now = datetime.now()
            if period == 'day':
                start_time = now - timedelta(days=1)
            elif period == 'week':
                start_time = now - timedelta(weeks=1)
            elif period == 'month':
                start_time = now - timedelta(days=30)
            else:
                start_time = now - timedelta(days=1)
            
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT 
                        MIN(temperature_c) as temp_min,
                        MAX(temperature_c) as temp_max,
                        AVG(temperature_c) as temp_avg,
                        MIN(humidity) as humidity_min,
                        MAX(humidity) as humidity_max,
                        AVG(humidity) as humidity_avg,
                        COUNT(*) as reading_count
                    FROM climate_readings
                    WHERE timestamp >= ?
                """, (start_time.isoformat(),))
                
                row = cursor.fetchone()
                if row and row[6] > 0:  # reading_count > 0
                    return {
                        'period': period,
                        'start_time': start_time.isoformat(),
                        'end_time': now.isoformat(),
                        'temperature': {
                            'min': round(row[0], 1) if row[0] else None,
                            'max': round(row[1], 1) if row[1] else None,
                            'avg': round(row[2], 1) if row[2] else None
                        },
                        'humidity': {
                            'min': round(row[3], 1) if row[3] else None,
                            'max': round(row[4], 1) if row[4] else None,
                            'avg': round(row[5], 1) if row[5] else None
                        },
                        'reading_count': row[6]
                    }
                return None
                
        except sqlite3.Error as e:
            self.logger.error(f"Failed to get statistics: {e}")
            return None
    
    def cleanup_old_data(self) -> int:
        """
        Remove readings older than retention period.
        
        Returns:
            Number of records deleted
        """
        try:
            cutoff_time = datetime.now() - timedelta(days=self.retention_days)
            
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    DELETE FROM climate_readings 
                    WHERE timestamp < ?
                """, (cutoff_time.isoformat(),))
                deleted_count = cursor.rowcount
                conn.commit()
                
                if deleted_count > 0:
                    self.logger.info(f"Deleted {deleted_count} old records (older than {self.retention_days} days)")
                
                return deleted_count
                
        except sqlite3.Error as e:
            self.logger.error(f"Failed to cleanup old data: {e}")
            return 0
    
    def export_to_json(self, output_path: str, start_time: Optional[datetime] = None,
                      end_time: Optional[datetime] = None) -> bool:
        """
        Export data to JSON format.
        
        Args:
            output_path: Path to output JSON file
            start_time: Start of time range (optional)
            end_time: End of time range (optional)
        
        Returns:
            True if successful, False otherwise
        """
        try:
            data = self.get_historical_data(start_time, end_time, limit=100000)
            
            with open(output_path, 'w') as f:
                json.dump(data, f, indent=2)
            
            self.logger.info(f"Exported {len(data)} records to {output_path}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to export to JSON: {e}")
            return False
    
    def export_to_csv(self, output_path: str, start_time: Optional[datetime] = None,
                     end_time: Optional[datetime] = None) -> bool:
        """
        Export data to CSV format.
        
        Args:
            output_path: Path to output CSV file
            start_time: Start of time range (optional)
            end_time: End of time range (optional)
        
        Returns:
            True if successful, False otherwise
        """
        try:
            data = self.get_historical_data(start_time, end_time, limit=100000)
            
            if not data:
                self.logger.warning("No data to export")
                return False
            
            with open(output_path, 'w', newline='') as f:
                writer = csv.DictWriter(f, fieldnames=data[0].keys())
                writer.writeheader()
                writer.writerows(data)
            
            self.logger.info(f"Exported {len(data)} records to {output_path}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to export to CSV: {e}")
            return False
    
    def close(self):
        """Close database connection."""
        self.logger.info("Database connection closed")

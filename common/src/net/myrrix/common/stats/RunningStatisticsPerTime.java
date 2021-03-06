/*
 * Copyright Myrrix Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package net.myrrix.common.stats;

import java.io.Serializable;
import java.util.Deque;
import java.util.LinkedList;
import java.util.concurrent.TimeUnit;

import com.google.common.base.Preconditions;

/**
 * @author Sean Owen
 * @since 1.0
 */
public final class RunningStatisticsPerTime implements Serializable {

  private final WeightedRunningAverage average;
  private double min;
  private double max;
  private final long bucketTimeMS;
  private final Deque<RunningStatistics> subBuckets;
  private long frontBucketValidUntil;

  public RunningStatisticsPerTime(TimeUnit timeUnit) {
    int timeUnitOrdinal = timeUnit.ordinal();
    Preconditions.checkArgument(timeUnitOrdinal >= TimeUnit.MINUTES.ordinal(), "Unsupported time unit: %s", timeUnit);
    TimeUnit subTimeUnit = TimeUnit.values()[timeUnitOrdinal - 1];
    int numBuckets = (int) subTimeUnit.convert(1, timeUnit);

    average = new WeightedRunningAverage();
    min = Double.NaN;
    max = Double.NaN;
    bucketTimeMS = TimeUnit.MILLISECONDS.convert(1, subTimeUnit);
    subBuckets = new LinkedList<RunningStatistics>();
    for (int i = 0; i < numBuckets; i++) {
      subBuckets.add(new RunningStatistics());
    }
    frontBucketValidUntil = System.currentTimeMillis() + bucketTimeMS;
  }

  public synchronized void refresh() {
    long now = System.currentTimeMillis();
    while (now > frontBucketValidUntil) {

      RunningStatistics removedBucket = subBuckets.removeLast();
      int count = removedBucket.getCount();
      if (count > 0) {
        average.removeDatum(removedBucket.getAverage(), count);
      }

      if (removedBucket.getMin() <= min) {
        double newMin = Double.NaN;
        for (RunningStatistics bucket : subBuckets) {
          double bucketMin = bucket.getMin();
          if (Double.isNaN(newMin) || bucketMin < newMin) {
            newMin = bucketMin;
          }
        }
        min = newMin;
      }
      if (removedBucket.getMax() >= max) {
        double newMax = Double.NaN;
        for (RunningStatistics bucket : subBuckets) {
          double bucketMax = bucket.getMax();
          if (Double.isNaN(newMax) || bucketMax > newMax) {
            newMax = bucketMax;
          }
        }
        max = newMax;
      }

      subBuckets.addFirst(new RunningStatistics());
      frontBucketValidUntil += bucketTimeMS;
    }
  }

  public synchronized void addDatum(double value) {
    refresh();
    average.addDatum(value);
    subBuckets.getFirst().addDatum(value);
    if (Double.isNaN(min) || value < min) {
      min = value;
    }
    if (Double.isNaN(max) || value > max) {
      max = value;
    }
  }

  public int getCount() {
    return average.getCount();
  }

  public double getAverage() {
    return average.getAverage();
  }

  public synchronized double getMin() {
    return min;
  }

  public synchronized double getMax() {
    return max;
  }

}

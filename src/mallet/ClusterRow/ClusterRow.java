import java.io.File;
import java.io.*;
import java.util.*;
import java.util.regex.*;

import cc.mallet.types.Metric;
import cc.mallet.types.Instance;
import cc.mallet.types.InstanceList;
import cc.mallet.types.SparseVector;
import cc.mallet.types.NormalizedDotProductMetric;
import cc.mallet.cluster.Clustering;
import cc.mallet.cluster.KMeans;
import cc.mallet.util.VectorStats;
import cc.mallet.pipe.*;
import cc.mallet.pipe.iterator.FileIterator;
import cc.mallet.pipe.iterator.CsvIterator;

public class ClusterRow {
	static public void main(String[] args) throws FileNotFoundException {
		String path = "mturk0127.mallet";
		int numClusters = 50;
		if (args.length > 1) {
			path = args[0];
		}
		if (args.length > 2) {
			numClusters = Integer.parseInt(args[1]);
		}
		if (args.length == 0) {
			System.err.println("Usage: ClusterRow [/path/to/mallet/file] [# of clusters]");
			System.err.println("Default Values: " + path + " " + numClusters);
		}

		ArrayList<Pipe> pipeList = new ArrayList<Pipe>();
		// pipeList.add(new Target2Label());
		pipeList.add(new Input2CharSequence());
		pipeList.add(new CharSequence2TokenSequence());
		pipeList.add(new TokenSequenceLowercase());
		pipeList.add(new TokenSequenceRemoveStopwords());
		pipeList.add(new TokenSequence2FeatureSequence());
		pipeList.add(new FeatureSequence2FeatureVector());

		InstanceList instances = new InstanceList(new SerialPipes(pipeList));
		//instances.addThruPipe(new FileIterator("/Users/bahn/work/mallet/sample-data/web/en"));
		instances.addThruPipe(new CsvIterator(path, "(\\S+)\\s+(.*)", 2, 0, 1));
		System.out.println("# The number of instances: " + instances.size());
		System.out.println("# The number of clusters: " + numClusters);
		System.out.println("# source file: " + path);
		
		Metric metric = new NormalizedDotProductMetric();
		KMeans kmeans = new KMeans(instances.getPipe(), numClusters, metric, KMeans.EMPTY_DROP);
		
		Clustering clustering = kmeans.cluster(instances);
		InstanceList[] clusters = clustering.getClusters();
		
		Pattern pattern = Pattern.compile("\\d+_\\d+_\\d+_\\d+_(.+)");
		
		//int clusterIndex = 0;
		for (InstanceList cluster: clusters) {
			//clusterIndex++;
			//System.out.println(clusterIndex + ": " + cluster.size());
			
		  	SparseVector clusterMean = VectorStats.mean(cluster);
		  	Instance center = null;
		  	double minDist = Double.MAX_VALUE;
		  	for (Instance instance: cluster) {
		  		double dist = metric.distance(clusterMean, (SparseVector)instance.getData());
		  		if (dist < minDist) {
		  			minDist = dist;
		  			center = instance;
		  		}
		  	}
		  	
			System.out.println();
			for (Instance instance: cluster) {
				String name = instance.getName().toString();
				System.out.println(name);
				if (name.startsWith("file:")) {
					// trim the beginning substring "file:"
					File file = new File(name.substring(5));
					
					// take only the name part. remove the path.
					name = file.getName();
					
					// trim the trailing extension
					if (name.endsWith(".txt")) {
						name = name.substring(0, name.length() - 4);
					}
					
					// trim the starting date and revid
					Matcher matcher = pattern.matcher(name);
					if (matcher.find() && matcher.groupCount() == 1) {
						name = matcher.group(1);
					}
					
					if (center == instance) {
						System.out.println(name);
					} else {
						System.out.println(name);
					}
				}
			}
		}
		
		
	}
}

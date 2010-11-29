import java.io.File;
import java.io.UnsupportedEncodingException;
import java.io.PrintStream;
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

public class ClusterFiles {
	static public String getPlainName(Instance instance) {
		Pattern pattern = Pattern.compile("\\d+_\\d+_\\d+_\\d+_(.+)");

		String name = instance.getName().toString();
		if (name.startsWith("file:")) {
			// trim the beginning substring "file:"
			File file = new File(name.substring(5));
			
			// take only the name part. remove the path.
			name = file.getName();
			
			// trim the trailing extension
			if (name.endsWith(".txt")) {
				name = name.substring(0, name.length() - 4);
			}
			if (name.endsWith(".sentences")) {
				name = name.substring(0, name.length() - 10);
			}
			
			// trim the starting date and revid
			Matcher matcher = pattern.matcher(name);
			if (matcher.find() && matcher.groupCount() == 1) {
				name = matcher.group(1);
			}
		}

		return name;
	}

	static public void main(String[] args) {
		try {
			System.setOut(new PrintStream(System.out, false, "UTF8"));
		} catch (UnsupportedEncodingException e) {
		}
		if (args.length != 1 && args.length != 2) {
			System.err.println("Usage: ClusterFiles [/path/to/dir/including/text/files/] [# of clusters]");
			System.exit(1);
		}

		String path = args[0];
		int numClusters = 50;
		if (args.length >= 2) {
			numClusters = Integer.parseInt(args[1]);
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
		instances.addThruPipe(new FileIterator(path));
		System.out.println("# The number of instances: " + instances.size());
		System.out.println("# The number of clusters: " + numClusters);
		System.out.println("# Source directory: " + path);
		
		Metric metric = new NormalizedDotProductMetric();
		KMeans kmeans = new KMeans(instances.getPipe(), numClusters, metric, KMeans.EMPTY_DROP);
		
		Clustering clustering = kmeans.cluster(instances);
		InstanceList[] clusters = clustering.getClusters();
		
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
			if (center != null) {
				System.out.println(getPlainName(center));
			}
		  	
			for (Instance instance: cluster) {
				if (instance != center) {
					System.out.println(getPlainName(instance));
				}
			}

			System.out.println("");
		}
	}
}

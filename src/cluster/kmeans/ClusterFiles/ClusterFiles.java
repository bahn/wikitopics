import java.io.*;
import java.util.*;
import java.util.regex.*;
import java.net.URLDecoder;

import cc.mallet.types.*;
import cc.mallet.util.*;
import cc.mallet.pipe.*;
import cc.mallet.cluster.Clustering;
import cc.mallet.cluster.KMeans;
import cc.mallet.pipe.iterator.FileIterator;

public class ClusterFiles {
    static CommandOption.SpacedStrings classDirs =	new CommandOption.SpacedStrings
	(ClusterFiles.class, "input", "DIR...", true, null,
	 "The directories containing text files to be classified, one directory per class", null);

    static CommandOption.Integer numClusters = new CommandOption.Integer
	(ClusterFiles.class, "k", "[# of clusters]", true, 50,
	 "The number of clusters into which articles are grouped.", null);

    static CommandOption.String weighting = new CommandOption.String
	(ClusterFiles.class, "weighting", "[tf|idf|tfidf]", false, "idf",
	 "The term weighting function: tf, idf, or tfidf.", null);
    
    static CommandOption.String metricOption = new CommandOption.String
	(ClusterFiles.class, "metric", "[cosine|wsum|lm|kl]", false, "cosine",
	 "The distance metric: cosine, weighted sum, language model, kl divergence, etc.", null);

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
			name = name.replaceAll("%25", "%");
			try {
				name = URLDecoder.decode(name, "UTF8");
			} catch (java.io.UnsupportedEncodingException ex) {
				System.err.println("java.io.UnsupportedEncodingException while decoding the file name " + name);
			}
		}

		return name;
	}

	static public void main(String[] args) {
		// set print stream as utf-8
		// to make the output correctly encoded in utf-8.
		try {
			System.setOut(new PrintStream(System.out, false, "UTF8"));
		} catch (UnsupportedEncodingException e) {
		}

		CommandOption.setSummary (ClusterFiles.class,
						  "A tool for clustering with various term weighting and distance metrics\n");
		CommandOption.process (ClusterFiles.class, args);
    
		// check if command-line arguments are correct.
		if (args.length == 0) {
			CommandOption.getList(ClusterFiles.class).printUsage(false);
			System.exit (-1);
		}
		if (classDirs.value == null || classDirs.value.length == 0) {
			System.err.println ("You must include --input DIR1 DIR2 ...' in order to specify a "+
					"list of directories containing the documents for each class.");
			System.exit (-1);
		}
		
		if (weighting.value.equalsIgnoreCase("tf") ||
			weighting.value.equalsIgnoreCase("idf") ||
			weighting.value.equalsIgnoreCase("tfidf"))
		{
			// implemented methods of term weighting. do nothing.
		} else {
			System.err.println("The given weighting is not recognizable!");
			System.exit(-1);
		}
		
		Metric metric = new NormalizedDotProductMetric(); // cosine similarity
		if (metricOption.value.equalsIgnoreCase("cosine")) {
			// cosine similarity. do nothing.
		} else if (metricOption.value.equalsIgnoreCase("lm") || 
			metricOption.value.equalsIgnoreCase("wsum") || 
			metricOption.value.equalsIgnoreCase("kl"))
		{
			System.err.println("The given metric is valid but not implemented yet. Sorry!");
			System.exit(-1);
		} else {
			System.err.println("The given metric is not recognizable!");
			System.exit(-1);
		}

		// the pipes through which the input instances are coming.
		InstanceList instances = new InstanceList(new SerialPipes(new Pipe[] {
			new Target2Label(),
			new SaveDataInSource(),
			new Input2CharSequence("UTF8"),
			new CharSequence2TokenSequence(),
			new TokenSequenceLowercase(),
			new TokenSequenceRemoveStopwords(),
			new TokenSequence2FeatureSequence(),
			new FeatureSequence2FeatureVector()
			}));

		//instances.addThruPipe(new FileIterator("/Users/bahn/work/mallet/sample-data/web/en"));
		for (String path: classDirs.value) {
			instances.addThruPipe(new FileIterator(path, null, true)); // remove common prefix
		}
		System.out.println("# The number of instances: " + instances.size());
		System.out.println("# The number of clusters: " + numClusters.value);
		System.out.println("# Source directory: " + classDirs.value[0]);
		for (int i = 1; i < classDirs.value.length; i++) {
			System.out.println("#                   " + classDirs.value[i]);
		}
		System.out.println("# Term weighting: " + weighting.value);
		System.out.println("# Metric: " + metricOption.value);
		
		Alphabet alphabet = instances.getPipe().getDataAlphabet();
		Object[] tokens = alphabet.toArray();
		System.out.println("# Number of dimensions: " + tokens.length);
		
                if (instances.size() == 0) {
                    System.out.println();
                    System.out.println("# No instances are found. Quitting...");
                    return;
                }

		// determine document frequency for each term
		int[] df = new int[tokens.length];
		for (Instance instance : instances) {
			FeatureVector fv = (FeatureVector) instance.getData();
			int[] indices = fv.getIndices();
			for (int index: indices) {
				df[index]++;
			}
		}
		
		if (weighting.value.equalsIgnoreCase("idf")) {
			// idf term weighting
			int N = instances.size();
			for (Instance instance : instances) {
				FeatureVector fv = (FeatureVector) instance.getData();
				int[] indices = fv.getIndices();
				for (int index: indices) {
					double tf = fv.value(index);
					double idfcomp = Math.log((double)N/(double)df[index]) / Math.log(N+1);
					fv.setValue(index, tf * idfcomp);
				}
			}
		} else if (weighting.value.equalsIgnoreCase("tfidf")) {
			// tfidf term weighting
			int N = instances.size();

			// determine document length for each document
			int[] lend = new int[N];
			double lenavg = 0;
			for (int i = 0; i < N; i++) {
				Instance instance = instances.get(i);
				FeatureVector fv = (FeatureVector) instance.getData();
				int[] indices = fv.getIndices();
				double length = 0.0;
				for (int index: indices) {
					length += fv.value(index);
				}
				lend[i] = (int) length;
				lenavg += length;
			}
			if (N > 1) {
				lenavg /= (double)N;
			}
	
			for (int i = 0; i < N; i++) {
				Instance instance = instances.get(i);
				FeatureVector fv = (FeatureVector) instance.getData();
				int[] indices = fv.getIndices();
				for (int index: indices) {
					double tf = fv.value(index);
					double tfcomp = tf / ( tf + 0.5 + 1.5 * (double) lend[i] / lenavg );
					double idfcomp = Math.log((double)N/(double)df[index]) / Math.log(N+1);
					fv.setValue(index, tfcomp * idfcomp);
				}
			}
		}
		
		KMeans kmeans = new KMeans(instances.getPipe(), numClusters.value, metric, KMeans.EMPTY_DROP);
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

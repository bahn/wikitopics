// class Trends
// ============
// 
// reads in page views, runs the Trending Topics algorithm on it,
// and writes out the top 100 lists.
// 
// Note that it only works for the English Wikipedia (the projectname en).
// 
// Change log.
// Wednesday, May 26, 2010 -- Clean anchors and check if the page title is valid
// May 25th -- Ignore the pages that has less than 1000 views.

import java.io.*;
import java.util.*;
import java.util.zip.*;

public class Trends {
	/**
	 * Checks whether the file exists.
	 */
	public static boolean exists(String directory, String filename) {
		File file = new File(directory, filename);
		return file.exists();
	}

	/**
	 * Returns a BufferedReader. Handles gzipped files.
	 * 
	 * @param filename the name of the file to read from (can be .gz)
	 * @param the directory that the file is in
	 * @return BufferedReader to read from the given file name 
	 * @exception IOException if a stream cannot be created
	 */
	public static BufferedReader getBufferedReader(String directory, String filename) throws IOException {
		// look to see if an gzipped version of the file exists.
		if(!exists(directory, filename) && exists(directory, filename + ".gz")) {
			filename = filename + ".gz";
		}
		InputStream stream = new FileInputStream(new File(directory, filename));
		if (filename.endsWith(".gz")) {
			stream = new GZIPInputStream(stream);
		}
		return new BufferedReader(new InputStreamReader(stream, "utf-8"));
	}

	public static void incrementCounts(HashMap<String, Integer> accCounts, HashMap<String, Integer> dailyCounts) {
		Iterator<String> iter = dailyCounts.keySet().iterator();
		while (iter.hasNext()) {
			String pagetitle = iter.next();
			int count = dailyCounts.get(pagetitle);
			if (accCounts.containsKey(pagetitle)) {
				int currentAccCount = accCounts.get(pagetitle);
				accCounts.put(pagetitle, currentAccCount + count);
			} else {
				accCounts.put(pagetitle, count);
			}
		}
	}
	
	public static void decrementCounts(HashMap<String, Integer> accCounts, HashMap<String, Integer> dailyCounts) {
		Iterator<String> iter = dailyCounts.keySet().iterator();
		while (iter.hasNext()) {
			String pagetitle = iter.next();
			int count = dailyCounts.get(pagetitle);
			if (accCounts.containsKey(pagetitle)) {
				int currentAccCount = accCounts.get(pagetitle);
				int newCount = currentAccCount - count;
				if (newCount > 0) {
					accCounts.put(pagetitle, newCount);
				} else {
					accCounts.remove(pagetitle);
				}
			}
		}
	}
	
	/**
	 * Sorts a map in descending order by the counts (values)
	 * Put the result in a map of the same entry type as the input maps,
	 * and return it.
	 * The result returned is of type LinkedHashMap,
	 * so that the order is kept.
	 * 
	 * @param map
	 * @return a sorted new map
	 */
	static Map<String, Integer> sortByValue(HashMap<String, Integer> map, int threshold) {
		List<Map.Entry<String, Integer>> list = new LinkedList<Map.Entry<String, Integer>>(map.entrySet());
		Collections.sort(list, new Comparator<Map.Entry<String,Integer>>() {
			@Override
			public int compare(Map.Entry<String, Integer> o1,
					Map.Entry<String, Integer> o2) {
				return o2.getValue().compareTo(o1.getValue());
			}
		});
		// logger.info(list);
		Map<String, Integer> result = new LinkedHashMap<String, Integer>();
		for (Iterator<Map.Entry<String, Integer>> it = list.iterator(); it.hasNext() && threshold > 0;) {
			Map.Entry<String, Integer> entry = it.next();
			result.put(entry.getKey(), entry.getValue());
			threshold--;
		}
		return result;
	}
	
	public static boolean isValidTitle(String pagetitle)
	{
		String[] namespace_titles = {"Media",
				"Special",
				"Talk",
				"User",
			    "Talk", "User", "User_talk", "Project", "Project_talk", "File",
    		    "File_talk", "MediaWiki", "MediaWiki_talk", "Template",
    		    "Template_talk", "Help", "Help_talk", "Category",
    		    "Category_talk", "Portal", "Wikipedia", "Wikipedia_talk"};
		
		for (String title : namespace_titles) {
			if (pagetitle.startsWith(title + ":")) {
				return false;
			}
		}
		
		if (pagetitle.length() == 0) {
			return false;
		}
		char first_letter = pagetitle.charAt(0);
		if (first_letter >= 'a' && first_letter <= 'z') {
			return false;
		}
		
		String[] image_extensions = {"jpg", "gif", "png", "JPG", "PNG", "GIF", "txt", "ico"};
		for (String extension : image_extensions) {
			if (pagetitle.endsWith("." + extension)) {
				return false;
			}
		}
		
		String[] blacklist = {"404_error", "Main_Page", "Hypertext_Transfer_Protocol", "Favicon.ico", "Search", "index.html", "Wiki"};
		for (String culprit : blacklist) {
			if (culprit.equals(pagetitle)) {
				return false;
			}
		}
		
		return true;
	}
	
	public static String cleanAnchors(String pagetitle)
	{
		if (pagetitle.contains("#")) {
			int anchor_point = pagetitle.indexOf("#");
			String newTitle = pagetitle.substring(0, anchor_point);
			return newTitle;
		}
		return pagetitle;
	}
	
	/**
	 * @param args
	 */
	public static void main(String[] args) throws IOException {
		if (args.length < 1) {
			System.out.println("Usage: wikitrends pagecounts-path");
		}
		
		String directoryName = args[0];
		File dir = new File(directoryName);
		Queue<HashMap<String, Integer>> current15days = new LinkedList<HashMap<String, Integer>>();
		Queue<HashMap<String, Integer>> past15days = new LinkedList<HashMap<String, Integer>>();
		HashMap<String, Integer> currentAccCounts = new HashMap<String, Integer>();
		HashMap<String, Integer> pastAccCounts = new HashMap<String, Integer>();
		
		String[] dailyStatistics = dir.list();
		Arrays.sort(dailyStatistics);
		if (dailyStatistics != null) {
			for (int i=0; i<dailyStatistics.length; i++) {
				HashMap<String,Integer> todaysCounts = new HashMap<String,Integer>();
				String statsFile = dailyStatistics[i];
				System.out.print(statsFile);
				
				BufferedReader reader = getBufferedReader(directoryName, statsFile);
				int lineno = 0;
				while (reader.ready()) {
					String line = reader.readLine();
					lineno += 1;
					String[] fields = line.split(" ");
					if (fields[0].equals("en")) {
						if (fields.length>=3) {
							String pagetitle = fields[1];
							pagetitle = cleanAnchors(pagetitle);
							if (isValidTitle(pagetitle)) {
								int counts = Integer.parseInt(fields[2]);
								if (counts >= 1000) {
									todaysCounts.put(pagetitle, counts);
								}
							}
						}
					}
				}
				
				System.out.println("\t" + todaysCounts.size());

				incrementCounts(currentAccCounts, todaysCounts);
				current15days.add(todaysCounts);
				
				if (current15days.size() > 15) {
					HashMap<String,Integer> fifteenDaysAgo = current15days.poll();
					decrementCounts(currentAccCounts, fifteenDaysAgo);
					incrementCounts(pastAccCounts, fifteenDaysAgo);
					past15days.add(fifteenDaysAgo);
					if (past15days.size() > 15) {
						HashMap<String,Integer> thirtyDaysAgo = past15days.poll();
						decrementCounts(pastAccCounts, thirtyDaysAgo);
						
						// output most trending topics for today
						HashMap<String,Integer> countsDiffs = new HashMap<String,Integer>();
						incrementCounts(countsDiffs, currentAccCounts);
						decrementCounts(countsDiffs, pastAccCounts);
						
						Map<String, Integer> result = sortByValue(countsDiffs, 100);
						
						Iterator<Map.Entry<String, Integer>> iter = result.entrySet().iterator();
						while (iter.hasNext()) {
							Map.Entry<String, Integer> entry = iter.next();
							String pagetitle = entry.getKey();
							Integer counts = entry.getValue();
							System.out.println(pagetitle + "\t" + counts);
						}
					}
				}
			}
		}	
	}
}

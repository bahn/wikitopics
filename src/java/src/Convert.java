// class Convert
// =============
// 
// Reads in the events list and the directory in which the pagecounts data reside
// and writes the pageview counts for the list of the events.
// 
// Usage
// =====
// java wikitrends.Convert events-link pagecounts-dir
// 
// events-link
// 	the file that has the list of the links, each of which is a Wikipedia article.
// 	One of the typical filename is events_links_2009.
// 	The format of the file is as follows:
// 
// 20090101 0 BART_Police_shooting_of_Oscar_Grant
// 20090101 0 California
// 20090101 0 Bay_Area_Rapid_Transit
// 20090101 0 Fruitvale_%28BART_station%29
// 20090101 1 Israel
// 20090101 1 Jabalia
// 20090101 1 Gaza_Strip
// 20090101 1 Hamas
// 20090101 1 Nizar_Rayan
// ...
// 
// 	The fields of each line are delimited by a space.
// 	The first field contains the date on which the event has occurred, the second field contains the number of the event, and the third field the link that the event contains, one link every line. One event may have multiple links in it.
// 	Only the third field matters for this script. The first and second field does not matter.
// 
// pagecounts-dir
// 	the directory in which the pagecounts data are located. e.g. data/wikistats/aggregate/en_daily/.
// 	The pagecounts files follow the following name convention: pagecounts-20090101.gz or pagecounts-20080131-180000.gz.
// 
//
// Changelog.
//
// July 21, 2010 -- Do not print links that do not have statistics.
//                  Print the date in the correct format. Previously it was in a wrong format.
// July 21, 2010 -- capitalized each links.
//                  Note that if there is no pageviews for a particular day, 
//                  the counts is stored as zero, which is not necessarily appropriate.
//					The capitalization must only work for links but not for pagecounts.
//					The pagecounts must be preprocessed since they may have
//					duplicate titles if capitalized.
//
// Jun 30, 2010 -- made this file.

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.zip.GZIPInputStream;

public class Convert {
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
	
	public static boolean isValidTitle(String pagetitle)
	{
		String[] namespace_titles = {"Media",
				"Special",
				"Talk",
				"User",
			    "Talk", "User", "User_talk", "Project", "Project_talk", "File",
    		    "File_talk", "MediaWiki", "MediaWiki_talk", "Template",
    		    "Template_talk", "Help", "Help_talk", "Category",
    		    "Category_talk", "Portal", "Wikipedia", "Wikipedia_talk",
                    "P", "N"};
		
		for (String title : namespace_titles) {
			if (pagetitle.startsWith(title + ":")) {
				return false;
			}
		}
		
		if (pagetitle.length() == 0) {
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
		if (args.length < 2) {
			System.out.println("Usage: java wikitrends.Convert events-link pagecounts-dir");
			System.exit(0);
		}
		String eventsName = args[0];
		HashMap<String, HashMap<String, String>> links = new HashMap<String, HashMap<String, String>>();
		{ // read the list of events
			File eventsFile = new File(eventsName);
			BufferedReader reader = getBufferedReader(eventsFile.getParent(), eventsFile.getName());
			while (reader.ready()) {
				String line = reader.readLine();
				String[] fields = line.split(" ");
				String title = fields[2];
				title = cleanAnchors(title);
				if (isValidTitle(title)) {
					title = Character.toUpperCase(title.charAt(0)) + title.substring(1);
					if (!links.containsKey(title)) {
						links.put(title, new HashMap<String, String>());
					}
				}
			}
		}
		
		String directoryName = args[1];
		File dir = new File(directoryName);

		List<String> dates = new LinkedList<String>();
		String[] dailyStatistics = dir.list();
		Arrays.sort(dailyStatistics);
		if (dailyStatistics != null) {
			for (int i=0; i<dailyStatistics.length; i++) {
				String statsFile = dailyStatistics[i];
				System.out.println(statsFile);
				
				String date = statsFile.substring(11, 19);
				dates.add(date);
				
				BufferedReader reader = getBufferedReader(directoryName, statsFile);
				while (reader.ready()) {
					String line = reader.readLine();
					if (line == null) break;
					String[] fields = line.split(" ");
					if (fields[0].equals("en")) {
						if (fields.length>=3) {
							String pagetitle = fields[1];
							pagetitle = cleanAnchors(pagetitle);
							if (links.containsKey(pagetitle)) {
								HashMap<String, String> pageviews = links.get(pagetitle);
								String counts = fields[2];
								pageviews.put(date, counts);
							}
						}
					}
				}
			}
		}

		String[] linktexts = links.keySet().toArray(new String[links.size()]);
		Arrays.sort(linktexts);
		
		Collections.sort(dates);
		for (String link : linktexts) {
			if (false) {
				System.out.print(link + ":");
				HashMap<String, String> counts = links.get(link);
				for (String date : dates) {
					if (counts.containsKey(date)) {
						System.out.print(" " + counts.get(date));
					} else {
						System.out.print(" 0");
					}
				}
				System.out.println();
			} else {
				// new format
				HashMap<String, String> counts = links.get(link);
				if (counts.size() == 0) {
					// if there is no page view counts available,
					// skip the link
					continue;
				}
                link.replaceAll("\"", "\\\"");
				System.out.print("[\"" + link + "\", [");
				boolean firstPrint = true;
				for (String date : dates) {
					if (counts.containsKey(date)) {
						if (!firstPrint) {
							System.out.print(", ");
						} else {
							firstPrint = false;
						}
						String datef = Integer.parseInt(date.substring(4,6)) + "/" + Integer.parseInt(date.substring(6,8)) + "/" + date.substring(0,4);
						System.out.print("[\"" + datef + "\", " + counts.get(date) + "]");
					}
				}
				System.out.println("]]");
			}
		}
	}
}

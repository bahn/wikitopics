// class Redirect
// ==============
// 
// reads in the redirect pages, non-redirect pages, and pagecounts data,
// adjust counts so that the page views for the redirected pages into the pages to which that the redirects link,
// and writes the counts in the pagecounts data format.
// 
// Note that this script currently process only English data.
// 
// Output is written into the standard output. Redirection may be used to make the output written in a plain text file.
// 
// Usage
// =====
// java wikitrends.Redirect non_redirects.txt redirects.txt pagecounts.gz
// 
// non_redirects.txt
// 	the file that contains the list of non-redirect pages.
// 	Each line contains the title of a non-redirect page.
// 
// redirects.txt
// 	the file that contains the list of redirect pages.
// 	Each line contains a redirect page followed by the page to which it links, separated by a space.
// 
// pagecounts.gz
// 	the file that has the page views for each Wikipedia article.
// 
// Output
// ======
// The output is written into the standard output. No other files are written.
// 
// The output is in the format of the pagecounts data except for that there are no files for bytes.
// The fields as follows are written in each line, separated by a space.
// 
// projectname pagetitle pageview
// 
// Changelog.
//
// Jul 20, 2010 -- made this file.

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.HashMap;
import java.util.Vector;
import java.util.zip.GZIPInputStream;

public class Redirect {
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
		if (args.length < 3) {
			System.out.println("Usage: java wikitrends.Redirect non_redirects.txt redirects.txt pagecounts.gz");
			System.exit(0);
		}

		String[] nonRedirectsArray = null;
		HashMap<String, Boolean> nonRedirects = new HashMap<String, Boolean>();
		{// read non redirects
			String nonRedirectsFilename = args[0];
			File nonRedirectsFile = new File(nonRedirectsFilename);
			BufferedReader reader = getBufferedReader(nonRedirectsFile.getParent(), nonRedirectsFile.getName());
			Vector<String> vec = new Vector<String>();
			while (reader.ready()) {
				String line = reader.readLine();
				nonRedirects.put(line, true);
				vec.add(line);
			}
			nonRedirectsArray = vec.toArray(new String[vec.size()]);
		}
		
		HashMap<String, String> redirects = new HashMap<String, String>();
		{//read redirects
			String redirectsFilename = args[1];
			File redirectsFile = new File(redirectsFilename);
			BufferedReader reader = getBufferedReader(redirectsFile.getParent(), redirectsFile.getName());
			while (reader.ready()) {
				String line = reader.readLine();
				String[] fields = line.split(" ");
				String fromTitle = fields[0];
				String toTitle = fields[1];
				redirects.put(fromTitle, toTitle);
			}
		}
		
		HashMap<String, Integer> pageviews = new HashMap<String, Integer>();
		{
			String pagecountsFilename = args[2];
			File pagecountsFile = new File(pagecountsFilename);
			BufferedReader reader = getBufferedReader(pagecountsFile.getParent(), pagecountsFile.getName());
			while (reader.ready()) {
				String line = reader.readLine();
				String[] fields = line.split(" ");
				String lang = fields[0];
				if (lang.equals("en")) {
					if (isValidTitle(fields[1])) {
						String title = cleanAnchors(fields[1]);
						if (!title.isEmpty() && title.charAt(0) != '#') {
							title = Character.toUpperCase(title.charAt(0)) + title.substring(1);
							String originalTitle = title;
							while (redirects.containsKey(title)) {
								title = redirects.get(title);
								if (title.equals(originalTitle)) {
									break;
								}
							}
							if (nonRedirects.containsKey(title)) {
								int counts = Integer.parseInt(fields[2]);
								if (pageviews.containsKey(title)) {
									pageviews.put(title, pageviews.get(title) + counts);
								} else {
									pageviews.put(title, counts);
								}
							}
						}
					}
				}
			}
		}
		
		for (String link : nonRedirectsArray) {
			if (pageviews.containsKey(link)) {
				System.out.println("en " + link + " " + pageviews.get(link));
			}
		}
	}
}

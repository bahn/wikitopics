import java.io.*;

public class ClusterUsingLinks {
	public static void main(String[] args) throws java.io.FileNotFoundException, UnsupportedEncodingException, IOException {
		InputStream inputStream = new FileInputStream(new File(args[0]));
		BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, "utf-8"), 1048576);
//		scanner = new Scanner(inputstream, "utf-8");
//		while (scanner.hasNextLine()) {
//			scanner.nextLine();
//		}
		while (reader.ready()) {
			reader.readLine();
		}
		reader.close();
	}
}

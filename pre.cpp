
#include <sstream>
#include <iostream>
#include <string>
#include <fstream>

int main(){
	std::string line;
	
	while (std::getline(std::cin, line))
	{
		if(line != ""){
			if(line.at(0) != '"')
				std::cout << line << "\t{\n\tidCount[\""	<< line << "\"] = idCount[\"" << line << "\"] + 1;\n}\n\n";
			else
				std::cout << line << "\t{\n\tidCount["	<< line << "] = idCount[" << line << "] + 1;\n}\n\n";
		}
	}
	
}


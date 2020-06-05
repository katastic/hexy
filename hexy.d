/*

WE NEED BOTH ENDIANNESS versions! 640 0 480   for Tanktics res I think. But LBM format (which is IFF derived) is the opposite ENDIAN (because amiga?) so it's 
 
 litle endian
tanktics 80 02 00 00 E0 01 00 00 01 00 08 00 01 00 00
		 [   ]       [   ]       ?     [   ]  ?
 		  640		  480		  		8 bit?
[3x of these]
	@791196
	@829892
	@899548





"Not a valid IFF-85 file: First bytes should start with either: 'FORM', 'CAT ' or 'LIST'"



	- Support automatic patching and "fuzz" patching that randomly patches combinations to try.

	- WHAT do we do if... wait i forgot....

		OKAY, if we have a 2-byte or 4-byte variable, do we also search for OFFSETS?

			2 bytes. right?
			check index at 0, 2, 4, 6, 8, ...
			but should we also check 1, 3, 5, ... etc?

	- NOTE: We *can* have odd matches if we assume ALL matches are odd. Imagine a SEGMENT and the segment BEGINS at some sort of odd offset. But I don't even know if that's possible on an x86 system. Either way, consider it as an option later. But IN GENERAL it should all be EVEN in 2-byte mode.


*/
import std.stdio;
import std.algorithm;
import std.range;
import std.file : read;
import std.conv;

int main(string[] args)
	{
	if(args.length < 3)
		{
		writeln("error args #");
		writeln("./hexy file low# high# [max search length] [endian]");
		writeln("       tanktics.exe 640 480 10 true  (search for 640x480 within 10 bytes of each other)");
		writeln("                    low#");
		writeln("                      high#");
		writeln("                          max_length");
		writeln("                             endian_mode = true/false");
		writeln("TODO - MODE SELECT for 1/2/4 byte matches and float/doubles.") // TODO <-------------------------
		writeln("TODO - specify HEX, decimal integer, etc");
		writeln("TODO - strings, but it's not that hard to do this with grep");
		writeln("TODO - what about BOTH endian modes?");
		
			
		return -1;
		}

	auto bytes = cast(ubyte[]) read(args[1]); //f.rawRead(new char[1]);
//https://forum.dlang.org/thread/okhzmbhtzuurusfvsjmu@forum.dlang.org

// MODE 1 - search for value [of SIZE 1 byte, 2 byte, etc? + byte ordering/swapping BY DEFAULT?]
// MODE 2 - search for value
//			- if found, search for value2. if exceed "max length", fail match
// searching UNSIGNED vs SIGNED. bit and byte ordering. and floats/doubles.

// one val only
// NEED TO ADD multiple hex numbers ala > A1F25EE92913

	void draw_hex(int i)
		{
		assert(i >= 0);
		assert(i <= 15);
			if(i >= 0 && i <= 9){write(i);}
			if(i == 10){write("A");}
			if(i == 11){write("B");}
			if(i == 12){write("C");}
			if(i == 13){write("D");}
			if(i == 14){write("E");}
			if(i == 15){write("F");}
		}

	void toHex(int i)
		{	
		if(i > 15) 
			{
			auto r = i % 16; 
			toHex(i/16);
			draw_hex(r);	
			}else{
			draw_hex(i);
			}
		}


	int target_value = to!int(args[2]);
	int target2_value = to!int(args[3]);

	int MAX_SEARCH_LENGTH = 16;
	if(args.length > 4)MAX_SEARCH_LENGTH = to!int(args[4]);

	bool LITTLE_ENDIAN = false;
	if(args.length > 5)LITTLE_ENDIAN = to!bool(args[5]);
	
	int number_of_matches = 0;
	int SEARCH_BYTE_LENGTH = 2; // <------------ DATATYPE MODE SELECTOR switch

	bool found_first_match=false;
	int first_match_location=-1; //we also check this every cycle to see if we've passed MAX_SEARCH_LENGTH.


	// WARNING: NOTE 2-byte. 
	// [from] is BEGINNING but [to+1] is LAST byte. Because to is START of second element.
	void print_range(int from, int to)
		{
		write("raw 2-byte [");
		for(int i = from; i < to + 1; i+=2)  //NOTE +1 for 2-byte mode.
			{
//			writefln("%s %s-%s",i, from, to);
//			toHex(bytes[i]); //HEX
//			write(bytes[i], " "); //DEC 1 byte mode
			if(LITTLE_ENDIAN)
				write(256*bytes[i+1]+bytes[i], " "); //DEC 2 byte mode
			else
				write(256*bytes[i]+bytes[i+1], " "); //DEC 2 byte mode

			}
		writeln("]");	
		}

	for(int i = 0; i < bytes.length-SEARCH_BYTE_LENGTH+1; i+=SEARCH_BYTE_LENGTH)
		{
		if(SEARCH_BYTE_LENGTH == 1 && found_first_match == false && 
			bytes[i] == target_value)
			{
			found_first_match = true;
			first_match_location = i;
			continue;
			}
		if(SEARCH_BYTE_LENGTH == 2 && found_first_match == false)
				if( (LITTLE_ENDIAN && (bytes[i+1]*256 + bytes[i]) == target_value)
					||
					(!LITTLE_ENDIAN && (bytes[i]*256 + bytes[i+1]) == target_value))
			{
			found_first_match = true;
			first_match_location = i;
//			i++; //IMPORTANT, move cursor / disk head / index for two bytes so we don't then match a WRONG OFFSET. (2 bytes, then match the SECOND byte for the FIRST byte of the next match.)
			continue;
			}

		if(found_first_match == true && (i - first_match_location) > MAX_SEARCH_LENGTH)
			{//reset. failed to match the first to a second.
			found_first_match = false;
			} 

		if(SEARCH_BYTE_LENGTH == 1 && found_first_match == true && 
			bytes[i] == target_value)
			{
			found_first_match = false;
			number_of_matches++;
			writeln("FOUND MATCH @", first_match_location, " AND @", i, " dist=", (i - first_match_location) );
			print_range(first_match_location, i);
			}

		if(SEARCH_BYTE_LENGTH == 2 && found_first_match == true)
				if( (LITTLE_ENDIAN && (bytes[i+1]*256 + bytes[i]) == target2_value)
					||
					(!LITTLE_ENDIAN && (bytes[i]*256 + bytes[i+1]) == target2_value))
//			(bytes[i+1]*256 + bytes[i]) == target2_value)
			{
			int second_match_location=i;
			int dist=(i - first_match_location);
			assert(dist % 2 == 0, "NO ODD MATCHES for twobyte mode!!!"); 
			found_first_match = false;
			number_of_matches++;
			writeln("FOUND MATCH @", first_match_location, " AND @", i, " dist=", dist);
			print_range(first_match_location, second_match_location); 
				
			if(LITTLE_ENDIAN)
					{
					writefln("For values %s and %s ", 
						bytes[first_match_location +1]*256 + bytes[first_match_location ], 
						bytes[second_match_location+1]*256 + bytes[second_match_location]);
					}else{
					writefln("For values %s and %s ", 
						bytes[first_match_location ]*256 + bytes[first_match_location +1], 
						bytes[second_match_location]*256 + bytes[second_match_location+1]);
					}
	//		i++; //DURP don't update this till we're done using it!
			}

/*
		if(SEARCH_BYTE_LENGTH == 4 && found_first_match == false &&
			(bytes[i+3]*256*256*256 + bytes[i+2]*256*256 + bytes[i+1]*256 + bytes[i]) == target_value)
			{
			found_first_match = true;
			first_match_location = i;
			i+=3; //we move the scanning "cursor" past the length of the match. i++ + 3 = +4
			}
*/

		}
/*
	toHex2(1);
writeln();
	toHex2(2);
writeln();
	toHex2(9);
writeln();
	toHex2(10);
writeln();
	toHex2(11);
writeln();
	toHex2(12);
writeln();
	toHex2(13);
writeln();
toHex2(14);
writeln();
toHex2(15);
writeln();
toHex2(16);
writeln();
toHex2(17);
writeln();
toHex2(18);
writeln();
toHex2(19);
writeln();
toHex2(255);
writeln();
toHex2(256);
writeln();
toHex2(257);
writeln();

for(int i =64000; i < 65536+1; i++)
	{
	toHex2(i);
	writeln();
	}
*/
	writeln("Total matches: ", number_of_matches);

	return 0;
	}

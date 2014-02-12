/*Header file to color text and background in windows console applications

See http://www.cplusplus.com/articles/Eyhv0pDG/ for Windows inspiration.

Modified by Colm Ryan for some cross-platform ability.

Global variables - textcol,backcol,deftextcol,defbackcol,colorprotect
*/


#ifndef CONCOL_H
#define CONCOL_H

#ifdef _WIN32

#include<windows.h>
#include<iosfwd>

namespace concol
{
#ifndef INNER_CONCOL_H
#define INNER_CONCOL_H
	enum colour
	{
		BLACK=0,
		BOLDBLUE=1,
		BOLDGREEN=2,
		BOLDCYAN=3,
		BOLDRED=4,
		BOLDMAGENTA=5,
		BOLDYELLOW=6,
		BOLDWHITE=7,
		GREY=8,
		BLUE=9,
		GREEN=10,
		CYAN=11,
		RED=12,
		MAGENTA=13,
		YELLOW=14,
		WHITE,RESET=15
	};
#endif
	static HANDLE std_con_out;
	//Standard Output Handle
	static bool colorprotect=false;
	//If colorprotect is true, background and text colors will never be the same
	static colour textcol,backcol,deftextcol,defbackcol;
	/*textcol - current text color
	backcol - current back color
	deftextcol - original text color
	defbackcol - original back color*/

	inline void update_colors()
	{
		CONSOLE_SCREEN_BUFFER_INFO csbi;
		GetConsoleScreenBufferInfo(std_con_out,&csbi);
		textcol = colour(csbi.wAttributes & 15);
		backcol = colour((csbi.wAttributes & 0xf0)>>4);
	}

	inline void setcolor(colour textcolor,colour backcolor)
	{
		if(colorprotect && textcolor==backcolor)return;
		textcol=textcolor;backcol=backcolor;
		unsigned short wAttributes=((unsigned int)backcol<<4) | (unsigned int)textcol;
		SetConsoleTextAttribute(std_con_out,wAttributes);
	}

	inline void settextcolor(colour textcolor)
	{
		if(colorprotect && textcolor==backcol)return;
		textcol=textcolor;
		unsigned short wAttributes=((unsigned int)backcol<<4) | (unsigned int)textcol;
		SetConsoleTextAttribute(std_con_out,wAttributes);
	}

	inline void setbackcolor(colour backcolor)
	{
		if(colorprotect && textcol==backcolor)return;
		backcol=backcolor;
		unsigned short wAttributes=((unsigned int)backcol<<4) | (unsigned int)textcol;
		SetConsoleTextAttribute(std_con_out,wAttributes);
	}

	inline void concolinit()
	{
		std_con_out=GetStdHandle(STD_OUTPUT_HANDLE);
		update_colors();
		deftextcol=textcol;defbackcol=backcol;
	}

	template<class elem,class traits>
	inline std::basic_ostream<elem,traits>& operator<<(std::basic_ostream<elem,traits>& os,colour col)
	{os.flush();settextcolor(col);return os;}

	template<class elem,class traits>
	inline std::basic_istream<elem,traits>& operator>>(std::basic_istream<elem,traits>& is,colour col)
	{
		std::basic_ostream<elem,traits>* p=is.tie();
		if(p!=NULL)p->flush();
		settextcolor(col);
		return is;
	}
	
}	//end of namespace concol

#else

//Just use some ASCII escape sequences on Linux.  Most modern terminals should support this.

namespace concol{

	static const std::string RESET    = "\033[0m";
	static const std::string BLACK    = "\033[30m";      /* Black */
	static const std::string RED      = "\033[31m";      /* Red */
	static const std::string GREEN    = "\033[32m";      /* Green */
	static const std::string YELLOW   = "\033[33m";      /* Yellow */
	static const std::string BLUE     = "\033[34m";      /* Blue */
	static const std::string MAGENTA  = "\033[35m";      /* Magenta */
	static const std::string CYAN     = "\033[36m";      /* Cyan */
	static const std::string WHITE    = "\033[37m";      /* White */
	static const std::string BOLDBLACK    = "\033[1m\033[30m";      /* Bold Black */
	static const std::string BOLDRED      = "\033[1m\033[31m";      /* Bold Red */
	static const std::string BOLDGREEN    = "\033[1m\033[32m";      /* Bold Green */
	static const std::string BOLDYELLOW   = "\033[1m\033[33m";      /* Bold Yellow */
	static const std::string BOLDBLUE     = "\033[1m\033[34m";      /* Bold Blue */
	static const std::string BOLDMAGENTA  = "\033[1m\033[35m";      /* Bold Magenta */
	static const std::string BOLDCYAN     = "\033[1m\033[36m";      /* Bold Cyan */
	static const std::string BOLDWHITE    = "\033[1m\033[37m";      /* Bold White */

	//Dummy init function
	inline void concolinit() {};
}

#endif
#endif /*CONCOL_H*/

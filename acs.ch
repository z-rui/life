@x
	mvaddch(i, j, sim->cells[idx].alive ? '*' : ' ');
@y
	mvaddch(i, j, ' ' | (sim->cells[idx].alive ? A_REVERSE : 0));
@z

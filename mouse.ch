@x
	int playing = 0;
@y
	int playing = 0;
	int toggling = 0;
@z

@x
	initscr(); noecho(); keypad(stdscr, TRUE); cbreak();
@y
	initscr(); noecho(); keypad(stdscr, TRUE); cbreak();
	mousemask(BUTTON1_PRESSED|BUTTON1_RELEASED|REPORT_MOUSE_POSITION,
		NULL);
@z

@x
	case ' ': /* toggle */
		sim_toggle(sim, y * sim->cols + x);
		refresh();
		goto move;
@y
	case ' ': /* toggle */
toggle:
		sim_toggle(sim, y * sim->cols + x);
		refresh();
		goto move;
	case KEY_MOUSE:
		@<Handle mouse events@>;
		break;
@z

@x
@*Index.
@y
@ @<Handle mouse events@>=
{
	MEVENT event;
	if (getmouse(&event) == OK) {
		if (event.bstate & BUTTON1_PRESSED) {
			y = event.y;
			x = event.x;
			goto toggle;
		}
		if (event.bstate & BUTTON1_RELEASED)
			toggling = 0;
		if (toggling && (event.bstate & REPORT_MOUSE_POSITION)) {
			goto toggle;
		}
	}
}

@*Index.
@z

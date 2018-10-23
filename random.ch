@x
	case 'q':
		goto quit;
	}
}
@y
	case 'g':
		@<Randomly toggle cells@>;
		break;
	case 'q':
		goto quit;
	}
}

@ @<Randomly toggle cells@>=
{
	int i, j;

	for (i = 0; i < LINES; i++)
		for (j = 0; j < COLS; j++)
			if (rand() & 1)
				sim_toggle(sim, i * COLS + j);
}
@z

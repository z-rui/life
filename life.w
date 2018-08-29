@*Introduction.  This program is an exercise for programming with the
{\mc CURSES} library.
As its name suggests, it is a game of life simulator.

For more information,
see \.{https://en.wikipedia.org/wiki/Conway's\_Game\_of\_Life}.

@c
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

@* Integer sets.  Here we define a data structure that holds a set of
unsigned integers within a certain upper bound.  It will allow quick
lookup, add, delete and enumeration operations.

It is not based on hash table or binary search trees; only two arrays are
required.  The first array, |val|, contains the list of the integers
in the set, and the second one, |idx|, contains the indices of the numbers
in |val|.  That is, for an integer |i|, either |idx[i]==-1| (|i| is not
in the set), or |val[idx[i]]==i|.

@ Add. $\Theta(1)$.
@c
void intset_add(unsigned v, unsigned *size, unsigned val[], int idx[])
{
	if (idx[v] == -1) {
		val[*size] = v;
		idx[v] = *size;
		++*size;
	}
}

@ Delete. $\Theta(1)$. Deletion will leave a hole in the |val| array,
and we should fill in this hole by moving the last element to the hole,
and update the |idx| array accordingly.
However, deleting the last element is a special case.

@c
void intset_del(unsigned v, unsigned *size, unsigned val[], int idx[])
{
	if (idx[v] != -1) {
		--*size;
		val[idx[v]] = val[*size];
		idx[val[*size]] = idx[v];
		idx[v] = -1;
	}
}

@ Clear. $\Theta({\it size})$.
Note: this function does not set |size| to zero on the caller side;
it does not clear the values in the |val| array either.

@c
void intset_clear(unsigned size, unsigned val[], int idx[])
{
	while (size > 0)
		idx[val[--size]] = -1;
}

@* The Simulator.  The game of life is played on a rectangular board.
Each grid on the board has two states: alive or dead.  After an iteration,
the state of cells may change based on the states of their neighbors.
Simply put:
\item{$\bullet$} Less than two or more than three live neighbors turns
a live cell into dead.
\item{$\bullet$} Exactly three live neighbors turns a dead cell into alive;
\item{$\bullet$} In all other cases, the state of the cell is unchanged.

@ To simulate the game, we need a two-dimensional array recording the state of
each cell.  To calculate these lists efficiently, we also record the number
of live neighbors in the state of the cell.

@c
typedef struct {
	unsigned alive:1; /* 0 (dead) or 1 (alive) */
	unsigned live_neighbors:4; /* ranges from 0 to 8 */
} cell_t;

@ We also keep an integer set, |to_toggle|, in which we will store
the index of cells that are going to change its state.
In fact, we need two of such sets because the one for the current iteration
have to be stable when populating the one for the next iteration.
We use |set_index|, which toggles in every iteration,
to indicate which set we are accessing.

@c
typedef struct {
	unsigned rows, cols;
	cell_t *cells;
	int set_index; /* 0 or 1 */
	unsigned to_toggle_size;
	unsigned *to_toggle[2];
	int *to_toggle_idx;
} sim_t;

@ Constructor.
@c
void sim_dtor(sim_t *);
sim_t *sim_ctor(sim_t *sim, unsigned rows, unsigned cols)
{
	unsigned cells;

	assert(rows > 0 && cols > 0);
	if (sim == NULL)
		return NULL;
	memset(sim, 0, sizeof *sim);
	sim->rows = rows;
	sim->cols = cols;
	cells = rows * cols;
	if ((sim->cells = calloc(cells, sizeof *sim->cells)) == NULL)
		goto fail;
	if ((sim->to_toggle[0] = malloc(2 * cells * sizeof (unsigned))) == NULL)
		goto fail;
	sim->to_toggle[1] = sim->to_toggle[0] + cells;
	if ((sim->to_toggle_idx = malloc(cells * sizeof (int))) == NULL)
		goto fail;
	memset(sim->to_toggle_idx, -1, cells * sizeof (int));
	sim->to_toggle_size = 0;
	sim->set_index = 0;
	return sim;
fail:
	sim_dtor(sim);
	return NULL;
}

@ Destructor.
@c
void sim_dtor(sim_t *sim)
{
	free(sim->cells);
	free(sim->to_toggle[0]);
	free(sim->to_toggle_idx);
}

@ When toggling a cell, we update the |live_neighbors| field
of all its 8~neighbors.  And determine if the cell, together
with its neighbors, goes into the |to_toggle| set in the next
iteration.

The user interface needs to be updated upon toggling.
That part of work is done in the |toggle_callback| function,
which will be introduced in later sections.

@c
void toggle_callback(sim_t *sim, unsigned idx);
void sim_toggle(sim_t *sim, unsigned idx)
{
	unsigned near_idx[9];
	int i;
	unsigned *to_toggle;
	int alive;
	cell_t *cell;

	assert(idx < sim->rows * sim->cols);
	to_toggle = sim->to_toggle[sim->set_index];
	alive = !sim->cells[idx].alive;

	@<Calculate |near_idx|@>;
	@<Update cells@>;
	toggle_callback(sim, near_idx[4]);
}

@ The array |near_idx| contains 9 indices: one for the cell itself and
the others for the neighbors.  They are numbered as follows:
$$\bordermatrix{
&0&1&2&3&4&5&6&7&8\cr
&\nwarrow&\uparrow&\nearrow&
\leftarrow&\bullet&\rightarrow&
\swarrow&\downarrow&\searrow\cr
}$$

The board is wrapped around the boundary.  That is, the left neighbor
of a leftmost cell is the rightmost cell on the same row, and so on.
As a result, every cell has exactly 8~neighbors.

@<Calculate |near_idx|@>=
{
	unsigned i[3], j[3];
	int x, y, z;

	i[0] = i[1] = i[2] = idx / sim->cols;
	j[0] = j[1] = j[2] = idx % sim->cols;

	if (i[0]-- == 0) i[0] = sim->rows - 1;
	if (++i[2] == sim->rows) i[2] = 0;
	if (j[0]-- == 0) j[0] = sim->cols - 1;
	if (++j[2] == sim->cols) j[2] = 0;

	z = 0;
	for (x = 0; x < 3; x++)
		for (y = 0; y < 3; y++)
			near_idx[z++] = i[x] * sim->cols + j[y];
}

@ @<Update cells@>=
for (i = 0; i < 9; i++) {
	idx = near_idx[i];
	cell = &sim->cells[idx];
	if (i == 4)
		@<Toggle the state of the cell@>@;
	else
		@<Change the count of live neighbors@>;
	@<Add |cell| to |to_toggle| if it is to be toggled in the
		next iteration@>;
}

@ @<Toggle the state of the cell@>=
	cell->alive = alive;

@ @<Change the count of live neighbors@>=
if (alive) {
	assert(cell->live_neighbors < 8);
	cell->live_neighbors++;
} else {
	assert(cell->live_neighbors > 0);
	cell->live_neighbors--;
}

@ @<Add |cell| to |to_toggle|...@>=
if ((cell->alive && cell->live_neighbors != 2 &&
	cell->live_neighbors != 3) ||@|
	(!cell->alive && cell->live_neighbors == 3))
	intset_add(idx, &sim->to_toggle_size, to_toggle, sim->to_toggle_idx);
else
	intset_del(idx, &sim->to_toggle_size, to_toggle, sim->to_toggle_idx);

@ To get the next iteration, we go through the |to_toggle| list,
toggle the state of each cell, and obtain the |to_toggle| for
the next iteration.

@c
void sim_iterate(sim_t *sim)
{
	unsigned *to_toggle;
	unsigned to_toggle_size;
	int i;

	to_toggle = sim->to_toggle[sim->set_index];
	to_toggle_size = sim->to_toggle_size;

	sim->set_index = !sim->set_index; /* switch |to_toggle| set */
	intset_clear(to_toggle_size, to_toggle, sim->to_toggle_idx);
	sim->to_toggle_size = 0;

	for (i = 0; i < to_toggle_size; i++)
		sim_toggle(sim, to_toggle[i]);
}

@*User Interface.
In this section, we will use {\mc CURSES} functionalities
for the user interface.

@c
#include <curses.h>

@ When the state of a cell is toggled, we update the corresponding postion
on the screen.

@c
void toggle_callback(sim_t *sim, unsigned idx)
{
	int i, j;

	i = idx / sim->cols;
	j = idx % sim->cols;
	mvaddch(i, j, sim->cells[idx].alive ? '*' : ' ');
}

@ The main function contains several set-up and tear-down work,
and the main event loop.

@c
int main()
{
	int playing = 0;
	sim_t *sim;
	int ch;

	initscr(); noecho(); keypad(stdscr, TRUE); cbreak();
	if ((sim = sim_ctor(malloc(sizeof *sim), LINES, COLS)) == NULL) {
		fprintf(stderr, "initialization failed\n");
		goto quit;
	}

	for (;;) {
		ch = getch();
		if (playing)
			@<Handle key event in playing mode@>@;
		else 
			@<Handle key event in non-playing mode@>;
	}
quit:
	if (sim != NULL) {
		sim_dtor(sim);
		free(sim);
	}
	endwin();
}

@ In the playing mode, we can either stop playing or quit the program.
Note that the timeout for |getch| is positive in this mode, so |getch|
may return after timeout if no key has been pressed, in which case
we simply call |sim_iterate| and refresh the screen.

@<Handle key event in playing mode@>=
switch (ch) {
case '\n':
	playing = 0;
	curs_set(1);
	timeout(-1);
	break;
case 'q':
	goto quit;
default:
	goto sim_step;
}

@ In the non-playing mode, we can move the cursor, toggle the state of
a cell, step into the next iteration, or start playing.

@<Handle key event in non-playing mode@>=
{
	int y, x;

	getyx(stdscr, y, x);
	switch (ch) {
	case '\n': /* play */
		playing = 1;
		curs_set(0);
		timeout(200);
		break;
	case '.': /* step */
sim_step:
		sim_iterate(sim);
		refresh();
		break;
	case ' ': /* toggle */
		sim_toggle(sim, y * sim->cols + x);
		refresh();
		goto move;
	case 'h': case KEY_LEFT: /* $\leftarrow$ */
		x--;
		goto move;
	case 'j': case KEY_DOWN: /* $\downarrow$ */
		y++;
		goto move;
	case 'k': case KEY_UP: /* $\uparrow$ */
		y--;
		goto move;
	case 'l': case KEY_RIGHT: /* $\rightarrow$ */
		x++;
move:
		move(y, x);
		break;
	case 'q':
		goto quit;
	}
}

@*Index.

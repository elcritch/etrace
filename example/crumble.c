#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void Crumble_buy(char * what, int quantity, char * unit)
{
	printf("buy %d %s of %s\n", quantity, unit, what);
	sleep(1);
}

void Crumble_buy_stuff(void)
{
	Crumble_buy("sugar", 125, "grams");
	Crumble_buy("butter", 125, "grams");
	Crumble_buy("wheat", 200, "grams");
	Crumble_buy("salt", 1, "pinch");
	Crumble_buy("apple", 5, "pieces");
	sleep(1);
}

void Crumble_skin_and_dice(void)
{
	printf("skin apples and make little dices\n");
	sleep(1);
}

int Crumble_prepare_apples(void)
{
	Crumble_skin_and_dice();
	sleep(1);
	return 1 ;
}

int Crumble_mix(char * a, char * b, char * c, char * d)
{
	printf("mix %s with %s, %s and %s\n", a, b, c, d);
	sleep(1);
	return 1;
}


int Crumble_put(char * what, char * where)
{
	printf("put %s %s\n", what, where);
	sleep(1);
}

void Crumble_finalize(int apples, int crumble)
{
	Crumble_put("apples", "below");
	Crumble_put("crumble", "on top");
	sleep(1);
}

void Crumble_bake(char * what, int temperature_deg, int time_min)
{
	printf("cook %s at %d degrees for %d minutes\n",
			what,
			temperature_deg,
			time_min);
	sleep(1);
}

void Crumble_cook(void)
{
	Crumble_put("apple crumble", "in oven");
	Crumble_bake("apple crumble", 220, 45);
	sleep(1);
}

void Crumble_make_apple_crumble(void)
{
	int	apples ;
	int	crumble ;

	Crumble_buy_stuff();
	apples = Crumble_prepare_apples();
	crumble = Crumble_mix("butter", "sugar", "wheat", "salt");
	Crumble_finalize(apples, crumble);
	Crumble_cook();
	sleep(1);
}

int main(int argc, char * argv[])
{
	Crumble_make_apple_crumble();
	return 0 ;
}


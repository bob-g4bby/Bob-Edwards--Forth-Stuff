\ MINI-OOF demo - Bob Edwards April 2022

OBJECT CLASS
	4 VARI teeth#
	4 VARI height
	METHOD SPEAK
	METHOD GREET
	METHOD WALK
	METHOD ADD.
END-CLASS PET

\ This defines a class in terms of data space and 'do nothing' methods
\ It can't be run - it's just a recipe for making pets 
\ Notice VARI allocates data in units of bytes, so 4 VARI is a long here

pub noname ." pet speaks" DROP	; ANON PET DEFINES SPEAK
pub noname ." pet greets" DROP	; ANON PET DEFINES GREET
pub noname ." pet walks" DROP	; ANON PET DEFINES WALK
pub noname  DROP + ." n1 + n2 = " . ; ANON PET DEFINES ADD.	( n1 n2 -- )

\ now the methods are reassigned to do useful stuff, using anonymous words
\ a named word can be assigned to a method instead :-
\ e.g. pub (WALK) ." pet walks" DROP	; ' (WALK) PET DEFINES WALK works just as well
\ notice each method drops the object which is top of stack
\ in more useful methods, the object is used to access it's other methods and variables

PET CLASS
	METHOD  HAPPY	\ an extra method is defined, cats can do more than pets
END-CLASS CAT

pub noname ." cat purrs" DROP ; ANON CAT DEFINES HAPPY

\ cats override pets for these two methods
pub noname ." cat says meow" DROP ; ANON CAT DEFINES SPEAK	
pub noname ." cat raises tail" DROP ; ANON CAT DEFINES GREET

PET CLASS
END-CLASS DOG

\ dogs override pets for these two methods
pub noname ." dog says wuff" DROP ; ANON DOG DEFINES SPEAK	
pub noname ." dog wags tail" DROP ; ANON DOG DEFINES GREET

\ now we create a cat and dog object to work with
\ objects have actual data and can run their methods

CAT NEW := TIBBY
DOG NEW := FIDO

20 TIBBY teeth# !
30 FIDO teeth# !
50 TIBBY height !
75 FIDO height !

TIBBY teeth# @ .	\ we can read data special to TIBBY
TIBBY height @ .
FIDO teeth# @ .		\ we can read FIDO data too
FIDO height @ .


TIBBY WALK			\ notice tibby is a PET so she can walk OK - that is an inherited method
34 56 FIDO ADD.		\ the parent PET method ADD. is also inherited here
TIBBY GREET			\ the PET method is overridden with a method special to CAT
FIDO SPEAK			\ the PET method is overridden with a method special to DOG
TIBBY HAPPY			\ cats do more than other pets with this extra method

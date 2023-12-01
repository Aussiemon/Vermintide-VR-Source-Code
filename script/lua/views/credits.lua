-- chunkname: @script/lua/views/credits.lua

CreditsSettings = {
	speed = 100,
	spacing = 30,
	header = {
		template = "credits_header"
	},
	title = {
		template = "credits_title"
	},
	person = {
		template = "credits_person"
	},
	legal = {
		template = "credits_legal"
	}
}
CreditsOffsets = {
	header = {
		person = -100,
		title = -100,
		legal = -200,
		header = -300
	},
	title = {
		person = -60,
		title = -100,
		legal = -150,
		header = -200
	},
	person = {
		title = -130,
		person = -75,
		legal = -150,
		header = -200
	},
	legal = {
		person = -100,
		title = -100,
		legal = -40,
		header = -250
	}
}
Credits = {
	{
		text = "Vermintide VR - The Hero Trials",
		type = "header"
	},
	{
		text = "Fatshark AB",
		type = "header"
	},
	{
		text = "CEO",
		type = "title"
	},
	{
		text = "Martin Wahlund",
		type = "person"
	},
	{
		text = "CTO",
		type = "title"
	},
	{
		text = "Rikard Blomberg",
		type = "person"
	},
	{
		text = "Game Director",
		type = "title"
	},
	{
		text = "Anders De Geer",
		type = "person"
	},
	{
		text = "Producer",
		type = "title"
	},
	{
		text = "Mårten Stormdal",
		type = "person"
	},
	{
		text = "Game Design",
		type = "title"
	},
	{
		text = "Markus Olsén",
		type = "person"
	},
	{
		text = "Technical Level Design",
		type = "title"
	},
	{
		text = "Johan Vargek",
		type = "person"
	},
	{
		text = "Level Design",
		type = "title"
	},
	{
		text = "Jonas Hellberg",
		type = "person"
	},
	{
		text = "Joakim Setterberg",
		type = "person"
	},
	{
		text = "Lead Programmer",
		type = "title"
	},
	{
		text = "Karl Werf",
		type = "person"
	},
	{
		text = "Programming",
		type = "title"
	},
	{
		text = "Sebastian Granstrand",
		type = "person"
	},
	{
		text = "Dmytro Vovk",
		type = "person"
	},
	{
		text = "Peter Nilsson",
		type = "person"
	},
	{
		text = "Patrik Wennersten",
		type = "person"
	},
	{
		text = "Axel Kinner",
		type = "person"
	},
	{
		text = "Christoffer Wiss",
		type = "person"
	},
	{
		text = "Peder Nordenström",
		type = "person"
	},
	{
		text = "Robin Hagblom",
		type = "person"
	},
	{
		text = "Environment Art",
		type = "title"
	},
	{
		text = "Niklas Eneqvist",
		type = "person"
	},
	{
		text = "Simon Jonasson",
		type = "person"
	},
	{
		text = "Character Art",
		type = "title"
	},
	{
		text = "Johan Lorentzen",
		type = "person"
	},
	{
		text = "Concept Art",
		type = "title"
	},
	{
		text = "Mathias Sällström",
		type = "person"
	},
	{
		text = "Mattias Rousk",
		type = "person"
	},
	{
		text = "Technical Art",
		type = "title"
	},
	{
		text = "Erik Lindqvist",
		type = "person"
	},
	{
		text = "Animation",
		type = "title"
	},
	{
		text = "Madeleine Von Post",
		type = "person"
	},
	{
		text = "VFX",
		type = "title"
	},
	{
		text = "Isak Bergh",
		type = "person"
	},
	{
		text = "Level Art",
		type = "title"
	},
	{
		text = "Tomas Holm",
		type = "person"
	},
	{
		text = "Sound Design",
		type = "title"
	},
	{
		text = "Danijel Djuric",
		type = "person"
	},
	{
		text = "Jonas Hellberg",
		type = "person"
	},
	{
		text = "David Wahlund",
		type = "person"
	},
	{
		text = "Head of Production",
		type = "title"
	},
	{
		text = "Erika Kling",
		type = "person"
	},
	{
		text = "CIO",
		type = "title"
	},
	{
		text = "Johan Jonker",
		type = "person"
	},
	{
		text = "COO & Head of Marketing",
		type = "title"
	},
	{
		text = "Sven Folkesson",
		type = "person"
	},
	{
		text = "Marketing & PR Coordinator",
		type = "title"
	},
	{
		text = "Cecilia Larsson",
		type = "person"
	},
	{
		text = "Marketing & PR Advisor",
		type = "title"
	},
	{
		text = "Gunnar Johansson",
		type = "person"
	},
	{
		text = "Community Manager",
		type = "title"
	},
	{
		text = "Leo Wakelin",
		type = "person"
	},
	{
		text = "Head Of Administration",
		type = "title"
	},
	{
		text = "Martin Karlsson",
		type = "person"
	},
	{
		text = "IT",
		type = "title"
	},
	{
		text = "Frank Hammar",
		type = "person"
	},
	{
		text = "QA Lead",
		localized = false,
		type = "title"
	},
	{
		text = "Otto Elggren",
		type = "person"
	},
	{
		text = "Quality Assurance",
		type = "title"
	},
	{
		text = "Philip Johansson",
		type = "person"
	},
	{
		text = "Additional Quality Assurance",
		localized = false,
		type = "title"
	},
	{
		text = "Eric Sernfalk",
		type = "person"
	},
	{
		text = "Emilia Johansson Kiviaho",
		type = "person"
	},
	{
		text = "Rasmus Liljenberg",
		type = "person"
	},
	{
		text = "Playtesters",
		type = "title"
	},
	{
		text = "Anja Wettergren",
		type = "person"
	},
	{
		text = "Warhammer: End Times - Vermintide",
		type = "header"
	},
	{
		text = "Fatshark AB",
		type = "header"
	},
	{
		text = "CEO",
		type = "title"
	},
	{
		text = "Martin Wahlund",
		type = "person"
	},
	{
		text = "CTO",
		type = "title"
	},
	{
		text = "Rikard Blomberg",
		type = "person"
	},
	{
		text = "Game Director",
		type = "title"
	},
	{
		text = "Anders De Geer",
		type = "person"
	},
	{
		text = "Head of Production",
		type = "title"
	},
	{
		text = "Erika Kling",
		type = "person"
	},
	{
		text = "Producer",
		type = "title"
	},
	{
		text = "Mårten Stormdal",
		type = "person"
	},
	{
		text = "Associate Producer",
		type = "title"
	},
	{
		text = "Robert Bäckström",
		type = "person"
	},
	{
		text = "Liam O'Neill",
		type = "person"
	},
	{
		text = "Assistant Producer",
		type = "title"
	},
	{
		text = "Kasper Batalje",
		type = "person"
	},
	{
		text = "Design Manager",
		type = "title"
	},
	{
		text = "Joakim Setterberg",
		type = "person"
	},
	{
		text = "Game Design",
		type = "title"
	},
	{
		text = "Victor Magnuson",
		type = "person"
	},
	{
		text = "Mats Andersson",
		type = "person"
	},
	{
		text = "Markus Olsén",
		type = "person"
	},
	{
		text = "Kasper Holmberg",
		type = "person"
	},
	{
		text = "Game Writer",
		type = "title"
	},
	{
		text = "Magnus Liljedahl",
		type = "person"
	},
	{
		text = "Story and Dialogue",
		type = "title"
	},
	{
		text = "Matthew Ward",
		type = "person"
	},
	{
		text = "Andy Hall",
		type = "person"
	},
	{
		text = "Lead Level Designer",
		type = "title"
	},
	{
		text = "Daniel Platt",
		type = "person"
	},
	{
		text = "Level Design",
		type = "title"
	},
	{
		text = "Adam Timén",
		type = "person"
	},
	{
		text = "Jennika Cederholm",
		type = "person"
	},
	{
		text = "Sara Sällemark",
		type = "person"
	},
	{
		text = "Lead Programmer",
		type = "title"
	},
	{
		text = "Joakim Wahlström",
		type = "person"
	},
	{
		text = "Programming Manager",
		type = "title"
	},
	{
		text = "Peter Nilsson",
		type = "person"
	},
	{
		text = "Technical Director",
		type = "title"
	},
	{
		text = "Robin Hagblom",
		type = "person"
	},
	{
		text = "CIO",
		type = "title"
	},
	{
		text = "Johan Jonker",
		type = "person"
	},
	{
		text = "Programming",
		type = "title"
	},
	{
		text = "Axel Kinner",
		type = "person"
	},
	{
		text = "Tom Batsford",
		type = "person"
	},
	{
		text = "Dmytro Vovk",
		type = "person"
	},
	{
		text = "Elias Stolt",
		type = "person"
	},
	{
		text = "Sebastian Granstrand",
		type = "person"
	},
	{
		text = "Christoffer Wiss",
		type = "person"
	},
	{
		text = "Adam Skoglund",
		type = "person"
	},
	{
		text = "Peder Nordenström",
		type = "person"
	},
	{
		text = "Niklas Häll",
		type = "person"
	},
	{
		text = "Karl Werf",
		type = "person"
	},
	{
		text = "Patrik Wennersten",
		type = "person"
	},
	{
		text = "Staffan Tejre",
		type = "person"
	},
	{
		text = "Philip Sköld",
		type = "person"
	},
	{
		text = "Additional Programming",
		type = "title"
	},
	{
		text = "Olle Grahn",
		type = "person"
	},
	{
		text = "Mathias Södermark",
		type = "person"
	},
	{
		text = "Branimir Sokolov",
		type = "person"
	},
	{
		text = "Egil Tordengren",
		type = "person"
	},
	{
		text = "Daniel Magnusson",
		type = "person"
	},
	{
		text = "Axel Lewenhaupt",
		type = "person"
	},
	{
		text = "Environment Art Manager",
		type = "title"
	},
	{
		text = "Arvid Nilsson",
		type = "person"
	},
	{
		text = "Lead Environment Artist",
		type = "title"
	},
	{
		text = "Robert Berg",
		type = "person"
	},
	{
		text = "Environment Art",
		type = "title"
	},
	{
		text = "Niklas Eneqvist",
		type = "person"
	},
	{
		text = "Robin Lundin",
		type = "person"
	},
	{
		text = "Simon Jonasson",
		type = "person"
	},
	{
		text = "Character Art & Outsourcing Manager",
		type = "title"
	},
	{
		text = "Johan Lorentzen",
		type = "person"
	},
	{
		text = "Corpses Critter Statues Artist",
		type = "title"
	},
	{
		text = "Gabriel Forsén",
		type = "person"
	},
	{
		text = "Concept Art",
		type = "title"
	},
	{
		text = "Niklas Frostgård",
		type = "person"
	},
	{
		text = "Mathias Sällström",
		type = "person"
	},
	{
		text = "Mattias Rousk",
		type = "person"
	},
	{
		text = "Petter Lundh",
		type = "person"
	},
	{
		text = "Jonas Norlén",
		type = "person"
	},
	{
		text = "Patrik Rosander",
		type = "person"
	},
	{
		text = "Lead Animator & TA",
		type = "title"
	},
	{
		text = "Mikael Hansson",
		type = "person"
	},
	{
		text = "Erik Lindqvist",
		type = "person"
	},
	{
		text = "Animation",
		type = "title"
	},
	{
		text = "Madeleine Von Post",
		type = "person"
	},
	{
		text = "Elin Mikkelsen",
		type = "person"
	},
	{
		text = "Patrik Ånberg",
		type = "person"
	},
	{
		text = "David Nilsson",
		type = "person"
	},
	{
		text = "VFX",
		type = "title"
	},
	{
		text = "Isak Bergh",
		type = "person"
	},
	{
		text = "Level Art",
		type = "title"
	},
	{
		text = "Tomas Holm",
		type = "person"
	},
	{
		text = "Lead Sound Designer",
		type = "title"
	},
	{
		text = "David Wahlund",
		type = "person"
	},
	{
		text = "Sound Design",
		type = "title"
	},
	{
		text = "Jonas Hellberg",
		type = "person"
	},
	{
		text = "Danijel Djuric",
		type = "person"
	},
	{
		text = "Technical VO Designer",
		type = "title"
	},
	{
		text = "Johan Vargek",
		type = "person"
	},
	{
		text = "Audio Engineer",
		type = "title"
	},
	{
		text = "Linus Söderlund",
		type = "person"
	},
	{
		text = "Music",
		type = "title"
	},
	{
		text = "Jesper Kyd",
		type = "person"
	},
	{
		text = "Solo Performers",
		type = "title"
	},
	{
		text = "Cameron Stone",
		type = "person"
	},
	{
		text = "Diego Stocco",
		type = "person"
	},
	{
		text = "Roger Neill",
		type = "person"
	},
	{
		text = "COO & Head of Marketing",
		type = "title"
	},
	{
		text = "Sven Folkesson",
		type = "person"
	},
	{
		text = "Marketing & PR Coordinator",
		type = "title"
	},
	{
		text = "Cecilia Larsson",
		type = "person"
	},
	{
		text = "Marketing & PR Advisor",
		type = "title"
	},
	{
		text = "Gunnar Johansson",
		type = "person"
	},
	{
		text = "Community Manager",
		type = "title"
	},
	{
		text = "Leo Wakelin",
		type = "person"
	},
	{
		text = "Head Of Administration",
		type = "title"
	},
	{
		text = "Martin Karlsson",
		type = "person"
	},
	{
		text = "IT Technician",
		type = "title"
	},
	{
		text = "Niklas Johansson",
		type = "person"
	},
	{
		text = "Additional IT Technician",
		type = "title"
	},
	{
		text = "Frank Hammar",
		type = "person"
	},
	{
		text = " ",
		type = "person"
	},
	{
		text = "Lead QA",
		type = "title"
	},
	{
		text = "Otto Elggren",
		type = "person"
	},
	{
		text = "Quality Assurance",
		type = "title"
	},
	{
		text = "Emilia Johansson Kiviaho",
		type = "person"
	},
	{
		text = "Rasmus Liljenberg",
		type = "person"
	},
	{
		text = "Viktor Dahlberg",
		type = "person"
	},
	{
		text = "Rickard Sjödén",
		type = "person"
	},
	{
		text = "Eric Sernfalk",
		type = "person"
	},
	{
		text = "Philip Johansson",
		type = "person"
	},
	{
		text = "Voices",
		type = "header"
	},
	{
		text = "Victor Saltzpyre, Witch Hunter",
		type = "title"
	},
	{
		text = "Tim Bentinck",
		type = "person"
	},
	{
		text = "Sienna Fuegonasus, Bright Wizard",
		type = "title"
	},
	{
		text = "Bethan Dickson Bate",
		type = "person"
	},
	{
		text = "Markus Kruber, Soldier",
		type = "title"
	},
	{
		text = "Dan Mersh",
		type = "person"
	},
	{
		text = "Kerillian, Waywatcher",
		type = "title"
	},
	{
		text = "Alix Wilton Regan",
		type = "person"
	},
	{
		text = "Bardin Goreksson, Dwarf Ranger",
		type = "title"
	},
	{
		text = "David Rintoul",
		type = "person"
	},
	{
		text = "Innkeeper",
		type = "title"
	},
	{
		text = "David Shaw Parker",
		type = "person"
	},
	{
		text = "Olesya Pimenova",
		type = "title"
	},
	{
		text = "Nicolette McKenzie",
		type = "person"
	},
	{
		text = "Rasknitt, Grey Seer",
		type = "title"
	},
	{
		text = "Andreas Rylander",
		type = "person"
	},
	{
		text = "Skaven",
		type = "title"
	},
	{
		text = "James Hogg",
		type = "person"
	},
	{
		text = "Indy Neidell",
		type = "person"
	},
	{
		text = "Fatshark Board of Directors - Non Executive",
		type = "header"
	},
	{
		text = "Thomas Lindgren, Chairman of The Board",
		type = "person"
	},
	{
		text = "Stefan Lindeberg",
		type = "person"
	},
	{
		text = "Stina Vällfors",
		type = "person"
	},
	{
		text = "Pixeldiet",
		type = "header"
	},
	{
		text = "Programming",
		type = "title"
	},
	{
		text = "Anders Elfgren",
		type = "person"
	},
	{
		text = "Fredrik Engkvist",
		type = "person"
	},
	{
		text = "Simon Lundmark",
		type = "person"
	},
	{
		text = "Nordic Games GmbH",
		type = "header"
	},
	{
		text = "Production Team:",
		type = "title"
	},
	{
		text = "Reinhard Pollice",
		type = "person"
	},
	{
		text = "Roger Joswig",
		type = "person"
	},
	{
		text = "Gennaro Giani",
		type = "person"
	},
	{
		text = "Martin Kreuch",
		type = "person"
	},
	{
		text = "Localization Manager:",
		type = "title"
	},
	{
		text = "Gennaro Giani",
		type = "person"
	},
	{
		text = "PR & Marketing Director:",
		type = "title"
	},
	{
		text = "Philipp Brock",
		type = "person"
	},
	{
		text = "PR & Marketing",
		type = "title"
	},
	{
		text = "Stephanie Harman",
		type = "person"
	},
	{
		text = "Social Media Manager:",
		type = "title"
	},
	{
		text = "Manuel Karl",
		type = "person"
	},
	{
		text = "Lead Graphic Artist:",
		type = "title"
	},
	{
		text = "Ernst Satzinger",
		type = "person"
	},
	{
		text = "Graphic Asset Assistant:",
		type = "title"
	},
	{
		text = "Tobias Grimus",
		type = "person"
	},
	{
		text = "Peter Hambsch",
		type = "person"
	},
	{
		text = "Age Rating Coordinator:",
		type = "title"
	},
	{
		text = "Thomas Reisinger",
		type = "person"
	},
	{
		text = "Web Developer:",
		type = "title"
	},
	{
		text = "Nina Trabe",
		type = "person"
	},
	{
		text = "Sales Director:",
		type = "title"
	},
	{
		text = "Georg Klotzberg",
		type = "person"
	},
	{
		text = "Sales:",
		type = "title"
	},
	{
		text = "Reinhold Schor",
		type = "person"
	},
	{
		text = "Nik Blower",
		type = "person"
	},
	{
		text = "Ian Warley",
		type = "person"
	},
	{
		text = "Digital Distribution:",
		type = "title"
	},
	{
		text = "Thomas Reisinger",
		type = "person"
	},
	{
		text = "Tim Grainer",
		type = "person"
	},
	{
		text = "Manufacturing:",
		type = "title"
	},
	{
		text = "Anton Seicarescu",
		type = "person"
	},
	{
		text = "Accounting & Office Management:",
		type = "title"
	},
	{
		text = "Marion Mayer",
		type = "person"
	},
	{
		text = "Anton Seicarescu",
		type = "person"
	},
	{
		text = "Business & Product Development Director:",
		type = "title"
	},
	{
		text = "Reinhard Pollice",
		type = "person"
	},
	{
		text = "Nordic Games GmbH Management:",
		type = "title"
	},
	{
		text = "Klemens Kreuzer",
		type = "person"
	},
	{
		text = "Lars Wingefors",
		type = "person"
	},
	{
		text = "Nordic Games NA Inc.",
		type = "title"
	},
	{
		text = "Adrienne Lauer",
		type = "person"
	},
	{
		text = "Eric Wuestmann",
		type = "person"
	},
	{
		text = "Klemens Kreuzer",
		type = "person"
	},
	{
		text = "Plan of Attack (External PR Agency)",
		type = "header"
	},
	{
		text = "Chris Clarke ",
		type = "person"
	},
	{
		text = "Derick Thomas",
		type = "person"
	},
	{
		text = "Tricia Gray ",
		type = "person"
	},
	{
		text = "Aidan Minter",
		type = "person"
	},
	{
		text = "Tom Davis",
		type = "person"
	},
	{
		text = "Audra McIver",
		type = "person"
	},
	{
		text = "Laura Pauzolyte",
		type = "person"
	},
	{
		text = "QLOC S.A.",
		type = "header"
	},
	{
		text = "General Manager",
		type = "title"
	},
	{
		text = "Adam Piesiak",
		type = "person"
	},
	{
		text = "Business Development Director",
		type = "title"
	},
	{
		text = "Pawel Grzywaczewski",
		type = "person"
	},
	{
		text = "Director of Account Management",
		type = "title"
	},
	{
		text = "Pawel Ziajka",
		type = "person"
	},
	{
		text = "Account Managers",
		type = "title"
	},
	{
		text = "Marta Olejniczak",
		type = "person"
	},
	{
		text = "Jakub Trudzik",
		type = "person"
	},
	{
		text = "Head of Quality Assurance",
		type = "title"
	},
	{
		text = "Sergiusz Slosarczyk",
		type = "person"
	},
	{
		text = "QA Project Managers",
		type = "title"
	},
	{
		text = "Bartosz Antecki",
		type = "person"
	},
	{
		text = "QA Lab Managers",
		type = "title"
	},
	{
		text = "Lukasz Miroslawski",
		type = "person"
	},
	{
		text = "Pawel Strzelczyk",
		type = "person"
	},
	{
		text = "QA Team Leader",
		type = "title"
	},
	{
		text = "Konrad Kolacki",
		type = "person"
	},
	{
		text = "QA Compliance Engineers",
		type = "title"
	},
	{
		text = "Ewa Angielska",
		type = "person"
	},
	{
		text = "Anna Bartosik",
		type = "person"
	},
	{
		text = "Rafal Dabrowski",
		type = "person"
	},
	{
		text = "Pawel Jaskolski",
		type = "person"
	},
	{
		text = "Maksym Sapetto",
		type = "person"
	},
	{
		text = "Kamil Zielinski",
		type = "person"
	},
	{
		text = "QA Testers",
		type = "title"
	},
	{
		text = "Sebastian Jaskolka",
		type = "person"
	},
	{
		text = "Marcin Kilinski",
		type = "person"
	},
	{
		text = "Dominika Kowalska",
		type = "person"
	},
	{
		text = "Lukasz Mazur",
		type = "person"
	},
	{
		text = "Marek Malagocki",
		type = "person"
	},
	{
		text = "Piotr Milewski",
		type = "person"
	},
	{
		text = "Jacek Zbikowski",
		type = "person"
	},
	{
		text = "Localization Testers",
		type = "title"
	},
	{
		text = "Henryk Borzymowski",
		type = "person"
	},
	{
		text = "Ismael Garcia-Marlowe",
		type = "person"
	},
	{
		text = "Laetitia Magniez",
		type = "person"
	},
	{
		text = "Angela Pellegrino",
		type = "person"
	},
	{
		text = "Polina Rutkowska",
		type = "person"
	},
	{
		text = "Maksym Sapetto",
		type = "person"
	},
	{
		text = "Pablo Venzke Avila",
		type = "person"
	},
	{
		text = "IT Manager",
		type = "title"
	},
	{
		text = "Tomasz Dziedzic",
		type = "person"
	},
	{
		text = "OMUK London",
		type = "header"
	},
	{
		text = "Director",
		type = "title"
	},
	{
		text = "Mark Estdale",
		type = "person"
	},
	{
		text = "Casting",
		type = "title"
	},
	{
		text = "OMUK",
		type = "person"
	},
	{
		text = "IT Manager",
		type = "title"
	},
	{
		text = "Juan Manuel Delfin",
		type = "person"
	},
	{
		text = "Victoria Prentice",
		type = "person"
	},
	{
		text = "Production Assistant",
		type = "title"
	},
	{
		text = "Ben Maltz-Jones",
		type = "person"
	},
	{
		text = "Recording Engineers",
		type = "title"
	},
	{
		text = "Juan Manuel Delfin",
		type = "person"
	},
	{
		text = "Victoria Prentice",
		type = "person"
	},
	{
		text = "Dialogue Editors",
		type = "title"
	},
	{
		text = "Lewis Bean",
		type = "person"
	},
	{
		text = "Matt Panayiotopoulos",
		type = "person"
	},
	{
		text = "Marta Puerto",
		type = "person"
	},
	{
		text = "Michael Redhead",
		type = "person"
	},
	{
		text = "Imagination Studios",
		type = "header"
	},
	{
		text = "Studio Director",
		type = "title"
	},
	{
		text = "Anton Söderhäll",
		type = "person"
	},
	{
		text = "Associate Producers",
		type = "title"
	},
	{
		text = "Peter Levin",
		type = "person"
	},
	{
		text = "Annika Torell Österman",
		type = "person"
	},
	{
		text = "Animation Manager",
		type = "title"
	},
	{
		text = "Andrew Hutchinson",
		type = "person"
	},
	{
		text = "Motion Capture Supervisor",
		type = "title"
	},
	{
		text = "Samuel Tyskling",
		type = "person"
	},
	{
		text = "Motion Capture Lead/Stage Manager",
		type = "title"
	},
	{
		text = "David Grice",
		type = "person"
	},
	{
		text = "Software Developer",
		type = "title"
	},
	{
		text = "Jacob Alenius",
		type = "person"
	},
	{
		text = "Motion Capture Artists",
		type = "title"
	},
	{
		text = "Nils Aulin",
		type = "person"
	},
	{
		text = "Johan Melander",
		type = "person"
	},
	{
		text = "Motion Capture Actors",
		type = "title"
	},
	{
		text = "Seth Ericson - Svenska Stuntgruppen (Skaven, Sienna Fuegonasus)",
		type = "person"
	},
	{
		text = "Nicklas Hansson - Svenska Stuntgruppen (Skaven, Markus Kruber, Victor Saltzpyre)",
		type = "person"
	},
	{
		text = "Tim Man - Svenska Stuntgruppen (Skaven, Kerillian, Bardin Goreksson)",
		type = "person"
	},
	{
		text = "Tove Vahlne (Kerillian, Sienna Fuegonasus)",
		type = "person"
	},
	{
		text = "Philip Hughes (Bardin Goreksson, Markus Kruber)",
		type = "person"
	},
	{
		text = "Bläck",
		type = "header"
	},
	{
		text = "Executive Producers",
		type = "title"
	},
	{
		text = "Tom Olsson",
		type = "person"
	},
	{
		text = "Peter Levin",
		type = "person"
	},
	{
		text = "Annika Torell Österman",
		type = "person"
	},
	{
		text = "Director",
		type = "title"
	},
	{
		text = "Fredrik Löfberg",
		type = "person"
	},
	{
		text = "Creative Director",
		type = "title"
	},
	{
		text = "Gustaf Holmsten",
		type = "person"
	},
	{
		text = "VFX Supervisor",
		type = "title"
	},
	{
		text = "Henrik Eklundh",
		type = "person"
	},
	{
		text = "Lead Character Artist",
		type = "title"
	},
	{
		text = "Jonas Skoog",
		type = "person"
	},
	{
		text = "Lead Animator",
		type = "title"
	},
	{
		text = "Jonas Ekman",
		type = "person"
	},
	{
		text = "Light and FX TD",
		type = "title"
	},
	{
		text = "Simon Rainerson",
		type = "person"
	},
	{
		text = "Lead Compositor",
		type = "title"
	},
	{
		text = "Peter Blomstrand",
		type = "person"
	},
	{
		text = "Mattepaint and Compositor",
		type = "title"
	},
	{
		text = "Calle Granström",
		type = "person"
	},
	{
		text = "Production Manager",
		type = "title"
	},
	{
		text = "Pontus Garmvild",
		type = "person"
	},
	{
		text = "Rigging TD",
		type = "title"
	},
	{
		text = "Peter Jemstedt",
		type = "person"
	},
	{
		text = "Production Assistant",
		type = "title"
	},
	{
		text = "Jonathan Forefält",
		type = "person"
	},
	{
		text = "Animator",
		type = "title"
	},
	{
		text = "Janak Thakker",
		type = "person"
	},
	{
		text = "Junior 3D Artist",
		type = "title"
	},
	{
		text = "Sebastian Salvo",
		type = "person"
	},
	{
		text = "Junior 3D Artist",
		type = "title"
	},
	{
		text = "Erik Tylberg",
		type = "person"
	},
	{
		text = "Junior Animator",
		type = "title"
	},
	{
		text = "Jonas Schild",
		type = "person"
	},
	{
		text = "Concept Artist",
		type = "title"
	},
	{
		text = "Andree Wallin",
		type = "person"
	},
	{
		text = "Character Artist",
		type = "title"
	},
	{
		text = "Daniel Bystedt",
		type = "person"
	},
	{
		text = " ",
		type = "header"
	},
	{
		text = "THIS SOFTWARE PRODUCT INCLUDES AUTODESK® STINGRAY® SOFTWARE, © 2016 AUTODESK, INC. ALL RIGHTS RESERVED.",
		type = "legal"
	},
	{
		text = "FATSHARK AB AND THE FATSHARK LOGO ARE TRADEMARKS OF FATSHARK AB. © 2016 FATSHARK AB. ALL RIGHTS RESERVED.",
		type = "legal"
	},
	{
		text = "WARHAMMER END TIMES: VERMINTIDE © COPYRIGHT GAMES WORKSHOP LIMITED 2016.",
		type = "legal"
	},
	{
		text = "WARHAMMER END TIMES: VERMINTIDE, THE WARHAMMER END TIMES: VERMINTIDE LOGO,",
		type = "legal"
	},
	{
		text = "GW, GAMES WORKSHOP, WARHAMMER, THE GAME OF FANTASY BATTLES, THE TWIN-TAILED COMET LOGO,",
		type = "legal"
	},
	{
		text = "AND ALL ASSOCIATED LOGOS, ILLUSTRATIONS, IMAGES, NAMES, CREATURES, RACES, VEHICLES,",
		type = "legal"
	},
	{
		text = "LOCATIONS, WEAPONS, CHARACTERS, AND THE DISTINCTIVE LIKENESS THEREOF ARE EITHER",
		type = "legal"
	},
	{
		text = "® OR TM, AND/OR © GAMES WORKSHOP LIMITED, VARIABLY REGISTERED AROUND THE WORLD, AND USED UNDER LICENCE.",
		type = "legal"
	},
	{
		text = "ALL RIGHTS RESERVED.",
		type = "legal"
	},
	{
		text = "© 2016 INTEL CORPORATION.",
		type = "legal"
	},
	{
		text = "INTEL, THE INTEL LOGO, INTEL CORE, AND INTEL INSIDE ARE TRADEMARKS OF INTEL CORPORATION IN THE U.S. AND/OR OTHER COUNTRIES.",
		type = "legal"
	},
	{
		text = "DOLBY AND THE DOUBLE-D SYMBOL ARE TRADEMARKS OF DOLBY LABORATORIES.",
		type = "legal"
	},
	{
		text = "DTS, THE SYMBOL, AND DTS PLUS THE SYMBOL TOGETHER ARE REGISTERED TRADEMARKS OF DTS, INC.",
		type = "legal"
	},
	{
		text = "AND DTS DIGITAL SURROUND IS A TRADEMARK OF DTS, INC",
		type = "legal"
	},
	{
		text = "Special Thanks To",
		type = "title"
	},
	{
		text = " ",
		type = "person"
	},
	{
		text = "Martin Tittenberger, MrT",
		type = "person"
	},
	{
		text = "Nathaniel Blue, Valve",
		type = "person"
	},
	{
		text = "Jonas Lundberg, Early Investor and Financial Advisor",
		type = "person"
	},
	{
		text = "Kostas Havlatzopoulos Public Clean",
		type = "person"
	},
	{
		text = "Rockelstad Slott, Making Christmas happen at Fatshark",
		type = "person"
	},
	{
		text = "Filip Strugar, Intel",
		type = "person"
	},
	{
		text = "George Bain, Intel",
		type = "person"
	},
	{
		text = "Erik Cubbage, Intel",
		type = "person"
	},
	{
		text = "Patrick Farrell, Intel",
		type = "person"
	},
	{
		text = "All our families and friends for their patience",
		type = "person"
	},
	{
		text = "All our great fans and beta testers",
		type = "person"
	},
	{
		text = "&",
		type = "person"
	},
	{
		text = "Games Workshop",
		type = "person"
	},
	{
		text = " ",
		type = "person"
	},
	{
		text = " ",
		type = "person"
	},
	{
		text = " ",
		type = "person"
	},
	{
		text = " ",
		type = "person"
	},
	{
		text = " ",
		type = "person"
	},
	{
		text = " ",
		type = "person"
	},
	{
		text = "...and John Blanche, for unsurpassed inspiration.",
		type = "person"
	}
}

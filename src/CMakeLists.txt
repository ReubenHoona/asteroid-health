add_library(
	asteroid-health
	main.cpp
	resources.qrc
)
set_target_properties(asteroid-health PROPERTIES PREFIX "")

target_link_libraries(
	asteroid-health
	PUBLIC
		Asteroid::AsteroidApp6
)

install(
	TARGETS asteroid-health
	DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# Relax, the guided breathing app: its own launcher entry (asteroid-relax.desktop), its own library
add_library(
	asteroid-relax
	relax/main_relax.cpp
	relax/relaxlog.cpp
	relax/relaxlog.h
	relax.qrc
)
set_target_properties(asteroid-relax PROPERTIES PREFIX "")

target_link_libraries(
	asteroid-relax
	PUBLIC
		Asteroid::AsteroidApp6
)

install(
	TARGETS asteroid-relax
	DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

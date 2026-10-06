#include <mach-o/dyld.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* Keep execution inside the app bundle for native resources and @rpath. */
int main(int argc, char **argv) {
    char location[PATH_MAX], binary[PATH_MAX];
    uint32_t length = sizeof(location);
    if (_NSGetExecutablePath(location, &length) != 0 || !realpath(location, binary)) {
        fputs("Cannot locate the MacAndFiles bundle.\n", stderr); return 1;
    }
    char *slash = strrchr(binary, '/');
    if (!slash) return 1;
    slash[1] = '\0';
    if (strlen(binary) + strlen("MacAndFiles") >= sizeof(binary)) return 1;
    strcat(binary, "MacAndFiles");
    char **forward = calloc((size_t)argc + 2, sizeof(char *));
    if (!forward) return 1;
    forward[0] = binary;
    forward[1] = "--cli";
    for (int i = 1; i < argc; ++i) forward[i + 1] = argv[i];
    execv(binary, forward);
    perror("Cannot start MacAndFiles CLI");
    free(forward);
    return 1;
}

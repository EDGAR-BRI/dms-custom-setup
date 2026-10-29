#include <security/pam_modules.h>
#include <security/pam_ext.h>
#include <string.h>

/*
 * pam_check_empty.so
 * Modulo PAM inteligente:
 * Si el campo de contraseña está vacío (el usuario solo dio Enter):
 *   -> Retorna PAM_SUCCESS (permite saltar pam_unix e ir directo a Howdy)
 * Si el usuario escribió una contraseña:
 *   -> Retorna PAM_IGNORE (permite que pam_unix valide la contraseña)
 */

PAM_EXTERN int pam_sm_authenticate(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    const char *authtok = NULL;
    int retval;

    retval = pam_get_authtok(pamh, PAM_AUTHTOK, &authtok, "Contraseña: ");
    if (retval != PAM_SUCCESS || authtok == NULL) {
        return PAM_AUTH_ERR;
    }

    if (strlen(authtok) == 0) {
        /* Campo vacío: saltar verificación tradicional e ir DIRECTO a Howdy */
        return PAM_SUCCESS;
    }

    /* Se escribió contraseña: continuar a pam_unix para validarla */
    return PAM_IGNORE;
}

PAM_EXTERN int pam_sm_setcred(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    return PAM_SUCCESS;
}

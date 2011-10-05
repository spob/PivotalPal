# The number of minutes to wait for a periodic job to complete. If the job does
# not complete in this time frame, OpenMind will assume it is dead and initiate
# a recovery
PERIODIC_JOB_TIMEOUT = 30

# The number of days to keep periodic jobs around
KEEP_PERIODIC_JOB_DAYS = 7

# Roles
ROLE_SUPERUSER = 'superuser'
ROLE_ADMIN = 'admin'

# Default rows per page
DEFAULT_ROWS_PER_PAGE = 20

INCREASE_TYPE_NONE = 'none'
INCREASE_TYPE_ANNUAL_ANNIVERSARY = 'annual_anniversary'
INCREASE_TYPE_ANNUAL_DAY_OF_YEAR = 'annual_day_of_year'

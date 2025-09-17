import logging, sys
from core.config import settings
def setup_logging():
    logging.basicConfig(
        level=settings.log_level,
        format="%(asctime)s | %(levelname)s | %(message)s",
        stream=sys.stdout,
    )
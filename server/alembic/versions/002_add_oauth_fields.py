"""Add OAuth fields to User model

Revision ID: 002
Revises: 001
Create Date: 2026-04-28 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table('users') as batch_op:
        batch_op.add_column(sa.Column('oauth_provider', sa.String(), nullable=True))
        batch_op.add_column(sa.Column('oauth_sub', sa.String(), nullable=True))
    op.create_index(op.f('ix_users_oauth_sub'), 'users', ['oauth_sub'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_users_oauth_sub'), table_name='users')
    with op.batch_alter_table('users') as batch_op:
        batch_op.drop_column('oauth_sub')
        batch_op.drop_column('oauth_provider')

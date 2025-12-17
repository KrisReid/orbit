import { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/api/client';
import { Plus, Pencil, Trash2 } from 'lucide-react';
import {
  FormModal,
  EditFormModal,
  TextInput,
  Textarea,
  SelectInput,
} from '@/components/ui';

interface Team {
  id: number;
  name: string;
  slug: string;
  description?: string | null;
}

interface TeamStats {
  task_count: number;
  task_type_count: number;
  is_unassigned_team: boolean;
}

export function TeamsSettings() {
  const queryClient = useQueryClient();
  
  // Modal states
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [editingTeam, setEditingTeam] = useState<Team | null>(null);
  const [deleteTeam, setDeleteTeam] = useState<Team | null>(null);
  const [teamStats, setTeamStats] = useState<TeamStats | null>(null);
  const [reassignTo, setReassignTo] = useState<number | undefined>(undefined);

  // Create form state
  const [createName, setCreateName] = useState('');
  const [createSlug, setCreateSlug] = useState('');
  const [createDescription, setCreateDescription] = useState('');

  // Edit form state
  const [editName, setEditName] = useState('');
  const [editDescription, setEditDescription] = useState('');

  // Sync edit form when editingTeam changes
  useEffect(() => {
    if (editingTeam) {
      setEditName(editingTeam.name);
      setEditDescription(editingTeam.description || '');
    }
  }, [editingTeam]);

  const { data: teams, isLoading } = useQuery({
    queryKey: ['teams'],
    queryFn: () => api.teams.list(),
  });

  const createMutation = useMutation({
    mutationFn: api.teams.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teams'] });
      handleCloseCreate();
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<{ name: string; description: string }> }) =>
      api.teams.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teams'] });
      setEditingTeam(null);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: ({ id, reassignTasksTo }: { id: number; reassignTasksTo?: number }) =>
      api.teams.delete(id, reassignTasksTo),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teams'] });
      handleCloseDelete();
    },
  });

  // Handlers
  const handleCloseCreate = () => {
    setShowCreateModal(false);
    setCreateName('');
    setCreateSlug('');
    setCreateDescription('');
  };

  const handleCreateSubmit = () => {
    createMutation.mutate({
      name: createName,
      slug: createSlug,
      description: createDescription || undefined,
    });
  };

  const handleNameChange = (value: string) => {
    setCreateName(value);
    // Auto-generate slug from name
    setCreateSlug(value.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''));
  };

  const handleEditSubmit = () => {
    if (!editingTeam) return;
    updateMutation.mutate({
      id: editingTeam.id,
      data: {
        name: editName,
        description: editDescription || undefined,
      },
    });
  };

  const handleDeleteClick = async (team: Team) => {
    try {
      const stats = await api.teams.getStats(team.id);
      setTeamStats(stats);
      setDeleteTeam(team);
    } catch (error) {
      console.error('Failed to get team stats:', error);
    }
  };

  const handleCloseDelete = () => {
    setDeleteTeam(null);
    setTeamStats(null);
    setReassignTo(undefined);
  };

  const handleConfirmDelete = () => {
    if (!deleteTeam) return;
    deleteMutation.mutate({
      id: deleteTeam.id,
      reassignTasksTo: reassignTo,
    });
  };

  if (isLoading) {
    return <div className="animate-pulse h-64 bg-gray-100 dark:bg-gray-800 rounded-xl" />;
  }

  const otherTeams = teams?.items?.filter(t => t.id !== deleteTeam?.id) || [];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Teams</h2>
        <button
          onClick={() => setShowCreateModal(true)}
          className="inline-flex items-center px-3 py-1.5 bg-primary-600 text-white text-sm rounded-lg hover:bg-primary-700"
        >
          <Plus className="h-4 w-4 mr-1" />
          Add Team
        </button>
      </div>

      {/* Teams Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {teams?.items?.map((team) => (
          <div
            key={team.id}
            className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-4"
          >
            <div className="flex items-center justify-between">
              <div>
                <h3 className="font-medium text-gray-900 dark:text-white">{team.name}</h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">@{team.slug}</p>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setEditingTeam(team)}
                  className="p-1 text-gray-400 hover:text-gray-600"
                >
                  <Pencil className="h-4 w-4" />
                </button>
                {team.slug !== 'unassigned' && (
                  <button
                    onClick={() => handleDeleteClick(team)}
                    className="p-1 text-red-400 hover:text-red-600"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                )}
              </div>
            </div>
            {team.description && (
              <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">{team.description}</p>
            )}
          </div>
        ))}
      </div>

      {/* Create Team Modal */}
      <FormModal
        isOpen={showCreateModal}
        onClose={handleCloseCreate}
        onSubmit={handleCreateSubmit}
        title="Add Team"
        submitLabel="Create"
        loadingLabel="Creating..."
        isLoading={createMutation.isPending}
      >
        <div className="space-y-4">
          <TextInput
            label="Name"
            required
            value={createName}
            onChange={(e) => handleNameChange(e.target.value)}
            placeholder="Engineering"
          />
          <TextInput
            label="Slug"
            required
            pattern="[a-z0-9-]+"
            value={createSlug}
            onChange={(e) => setCreateSlug(e.target.value)}
            placeholder="engineering"
          />
          <Textarea
            label="Description"
            value={createDescription}
            onChange={(e) => setCreateDescription(e.target.value)}
            rows={2}
            placeholder="Team description..."
          />
        </div>
      </FormModal>

      {/* Edit Team Modal */}
      <EditFormModal
        isOpen={!!editingTeam}
        onClose={() => setEditingTeam(null)}
        onSubmit={handleEditSubmit}
        title="Edit Team"
        isLoading={updateMutation.isPending}
      >
        <div className="space-y-4">
          <TextInput
            label="Name"
            required
            value={editName}
            onChange={(e) => setEditName(e.target.value)}
          />
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Slug
            </label>
            <input
              type="text"
              disabled
              value={editingTeam?.slug || ''}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-gray-100 dark:bg-gray-600 text-gray-500"
            />
            <p className="text-xs text-gray-500 mt-1">Slug cannot be changed</p>
          </div>
          <Textarea
            label="Description"
            value={editDescription}
            onChange={(e) => setEditDescription(e.target.value)}
            rows={2}
          />
        </div>
      </EditFormModal>

      {/* Delete Team Modal - uses FormModal since it needs custom content */}
      <FormModal
        isOpen={!!deleteTeam && !!teamStats}
        onClose={handleCloseDelete}
        onSubmit={handleConfirmDelete}
        title="Delete Team"
        submitLabel="Delete"
        loadingLabel="Deleting..."
        isLoading={deleteMutation.isPending}
      >
        {deleteTeam && teamStats && (
          <div className="space-y-4">
            <div className="p-3 bg-red-50 dark:bg-red-900/20 rounded-lg">
              <p className="text-sm text-red-800 dark:text-red-200">
                Are you sure you want to delete <strong>{deleteTeam.name}</strong>?
              </p>
            </div>

            {teamStats.task_count > 0 && (
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">
                  This team has <strong>{teamStats.task_count} tasks</strong> and{' '}
                  <strong>{teamStats.task_type_count} task types</strong>.
                </p>
                <SelectInput
                  label="Reassign tasks to"
                  value={reassignTo?.toString() || ''}
                  onChange={(e) => setReassignTo(e.target.value ? Number(e.target.value) : undefined)}
                  options={[
                    { value: '', label: 'Unassigned Team (default)' },
                    ...otherTeams.map((t) => ({ value: t.id.toString(), label: t.name })),
                  ]}
                />
                <p className="text-xs text-gray-500 mt-1">
                  Task types will be deleted. Tasks will be migrated to the target team's default task type.
                </p>
              </div>
            )}
          </div>
        )}
      </FormModal>
    </div>
  );
}

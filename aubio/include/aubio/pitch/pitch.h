/*
  Copyright (C) 2003-2013 Paul Brossier <piem@aubio.org>

  This file is part of aubio.

  aubio is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  aubio is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with aubio.  If not, see <http://www.gnu.org/licenses/>.

*/

#ifndef _AUBIO_PITCH_H
#define _AUBIO_PITCH_H

#ifdef __cplusplus
extern "C" {
#endif

/** \file

  Pitch detection object

  This file creates the objects required for the computation of the selected
  pitch detection algorithm and output the results, in midi note or Hz.

  \section pitch Pitch detection methods

  A list of the pitch detection methods currently available follows.

  \b \p default : use the default method

  Currently, the default method is set to \p yinfft .

  \b \p schmitt : Schmitt trigger

  This pitch extraction method implements a Schmitt trigger to estimate the
  period of a signal.

  This file was derived from the tuneit project, written by Mario Lang to
  detect the fundamental frequency of a sound.

  See http://delysid.org/tuneit.html

  \b \p fcomb : a fast harmonic comb filter

  This pitch extraction method implements a fast harmonic comb filter to
  determine the fundamental frequency of a harmonic sound.

  This file was derived from the tuneit project, written by Mario Lang to
  detect the fundamental frequency of a sound.

  See http://delysid.org/tuneit.html

  \b \p mcomb : multiple-comb filter

  This fundamental frequency estimation algorithm implements spectral
  flattening, multi-comb filtering and peak histogramming.

  This method was designed by Juan P. Bello and described in:

  Juan-Pablo Bello. ``Towards the Automated Analysis of Simple Polyphonic
  Music''.  PhD thesis, Centre for Digital Music, Queen Mary University of
  London, London, UK, 2003.

  \b \p yin : YIN algorithm

  This algorithm was developped by A. de Cheveigne and H. Kawahara and
  published in:

  De Cheveigné, A., Kawahara, H. (2002) "YIN, a fundamental frequency
  estimator for speech and music", J. Acoust. Soc. Am. 111, 1917-1930.

  see http://recherche.ircam.fr/equipes/pcm/pub/people/cheveign.html

  \b \p yinfft : Yinfft algorithm

  This algorithm was derived from the YIN algorithm. In this implementation, a
  Fourier transform is used to compute a tapered square difference function,
  which allows spectral weighting. Because the difference function is tapered,
  the selection of the period is simplified.

  Paul Brossier, [Automatic annotation of musical audio for interactive
  systems](http://aubio.org/phd/), Chapter 3, Pitch Analysis, PhD thesis,
  Centre for Digital music, Queen Mary University of London, London, UK, 2006.

  \example pitch/test-pitch.c
  \example examples/aubiopitch.c

*/

/** pitch detection object */
typedef struct _aubio_pitch_t aubio_pitch_t;

/** execute pitch detection on an input signal frame

  \param o pitch detection object as returned by new_aubio_pitch()
  \param in input signal of size [hop_size]
  \param out output pitch candidates of size [1]

*/
void aubio_pitch_do (aubio_pitch_t * o, fvec_t * in, fvec_t * out);

/** change yin or yinfft tolerance threshold

  \param o pitch detection object as returned by new_aubio_pitch()
  \param tol tolerance default is 0.15 for yin and 0.85 for yinfft

*/
uint_t aubio_pitch_set_tolerance (aubio_pitch_t * o, smpl_t tol);

/** deletion of the pitch detection object

  \param o pitch detection object as returned by new_aubio_pitch()

*/
void del_aubio_pitch (aubio_pitch_t * o);

/** creation of the pitch detection object

  \param method set pitch detection algorithm
  \param buf_size size of the input buffer to analyse
  \param hop_size step size between two consecutive analysis instant
  \param samplerate sampling rate of the signal

  \return newly created ::aubio_pitch_t

*/
aubio_pitch_t *new_aubio_pitch (char_t * method,
    uint_t buf_size, uint_t hop_size, uint_t samplerate);

/** set the output unit of the pitch detection object

  \param o pitch detection object as returned by new_aubio_pitch()
  \param mode set pitch units for output

  \return 0 if successfull, non-zero otherwise

*/
uint_t aubio_pitch_set_unit (aubio_pitch_t * o, char_t * mode);

/** set the silence threshold of the pitch detection object

  \param o pitch detection object as returned by new_aubio_pitch()
  \param silence level threshold under which pitch should be ignored, in dB

  \return 0 if successfull, non-zero otherwise

*/
uint_t aubio_pitch_set_silence (aubio_pitch_t * o, smpl_t silence);

/** set the silence threshold of the pitch detection object

  \param o pitch detection object as returned by ::new_aubio_pitch()

  \return level threshold under which pitch should be ignored, in dB

*/
smpl_t aubio_pitch_get_silence (aubio_pitch_t * o);

/** get the current confidence

  \param o pitch detection object as returned by new_aubio_pitch()

  \return the current confidence of the pitch algorithm

*/
smpl_t aubio_pitch_get_confidence (aubio_pitch_t * o);

#ifdef __cplusplus
}
#endif

#endif /* _AUBIO_PITCH_H */
